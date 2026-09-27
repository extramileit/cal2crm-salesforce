@RestResource(urlMapping='/booking/*')
global with sharing class BookingRestEndpoint {
    global class ContactPayload {
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
    }

    global class BookingPayload {
        public String id;
        public String title;
        public String start;
        public String end;
        public String location;
        public String notes;
    }

    global class CreateBookingRequest {
        public String idempotencyKey;
        public ContactPayload contact;
        public BookingPayload booking;
    }

    global class CreateBookingResponse {
        public Boolean processed;
        public String message;
        public Id accountId;
        public Id eventId;
    }

    @HttpPost
    global static CreateBookingResponse createBooking() {
        String body = RestContext.request.requestBody == null
            ? null
            : RestContext.request.requestBody.toString();
        CreateBookingRequest request = (CreateBookingRequest) JSON.deserialize(body, CreateBookingRequest.class);
        return BookingRestService.processRequest(request);
    }
}
