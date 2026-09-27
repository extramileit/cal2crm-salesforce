public with sharing class BookingRestService {
    public class BookingServiceException extends Exception {}

    public static BookingRestEndpoint.CreateBookingResponse processRequest(
        BookingRestEndpoint.CreateBookingRequest request
    ) {
        if (request == null || String.isBlank(request.idempotencyKey) || request.contact == null || request.booking == null) {
            throw new BookingServiceException('Missing required request fields.');
        }
        if (String.isBlank(request.contact.email)) {
            throw new BookingServiceException('contact.email is required.');
        }

        if (alreadyProcessed(request.idempotencyKey)) {
            BookingRestEndpoint.CreateBookingResponse duplicateResponse =
                new BookingRestEndpoint.CreateBookingResponse();
            duplicateResponse.processed = false;
            duplicateResponse.message = 'Request already processed for this idempotency key.';
            return duplicateResponse;
        }

        Account personAccount = findOrCreatePersonAccount(request.contact);
        Event bookingEvent = createBookingEvent(request.booking, personAccount.Id);
        insert bookingEvent;

        insert new Processed_Request__c(
            External_Key__c = request.idempotencyKey,
            Account__c = personAccount.Id,
            Event__c = bookingEvent.Id
        );

        BookingRestEndpoint.CreateBookingResponse response =
            new BookingRestEndpoint.CreateBookingResponse();
        response.processed = true;
        response.message = 'Booking stored successfully.';
        response.accountId = personAccount.Id;
        response.eventId = bookingEvent.Id;
        return response;
    }

    private static Boolean alreadyProcessed(String idempotencyKey) {
        Integer existing = [
            SELECT COUNT()
            FROM Processed_Request__c
            WHERE External_Key__c = :idempotencyKey
            LIMIT 1
        ];
        return existing > 0;
    }

    private static Account findOrCreatePersonAccount(BookingRestEndpoint.ContactPayload contactPayload) {
        List<Account> existingAccounts = [
            SELECT Id
            FROM Account
            WHERE PersonEmail = :contactPayload.email
            LIMIT 1
        ];
        if (!existingAccounts.isEmpty()) {
            return existingAccounts[0];
        }

        List<RecordType> personTypes = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsPersonType = true
            LIMIT 1
        ];
        if (personTypes.isEmpty()) {
            throw new BookingServiceException('No Person Account record type found.');
        }

        Account newPerson = new Account();
        newPerson.RecordTypeId = personTypes[0].Id;
        newPerson.FirstName = contactPayload.firstName;
        newPerson.LastName = String.isBlank(contactPayload.lastName)
            ? 'Unknown'
            : contactPayload.lastName;
        newPerson.PersonEmail = contactPayload.email;
        newPerson.PersonMobilePhone = contactPayload.phone;
        insert newPerson;
        return newPerson;
    }

    private static Event createBookingEvent(BookingRestEndpoint.BookingPayload bookingPayload, Id accountId) {
        Event bookingEvent = new Event();
        bookingEvent.WhoId = accountId;
        bookingEvent.Subject = String.isBlank(bookingPayload.title)
            ? 'Booking'
            : bookingPayload.title;
        bookingEvent.StartDateTime = parseDateTime(bookingPayload.start);
        bookingEvent.EndDateTime = parseDateTime(bookingPayload.end);
        bookingEvent.Location = bookingPayload.location;
        bookingEvent.Description = bookingPayload.notes;
        return bookingEvent;
    }

    private static Datetime parseDateTime(String value) {
        if (String.isBlank(value)) {
            throw new BookingServiceException('Booking start/end datetime is required.');
        }
        String normalized = value.replace('T', ' ').replace('Z', '');
        try {
            return Datetime.valueOfGmt(normalized);
        } catch (Exception ex) {
            throw new BookingServiceException('Invalid datetime format: ' + value);
        }
    }
}
