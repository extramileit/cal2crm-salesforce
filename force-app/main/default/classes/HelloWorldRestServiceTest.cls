@IsTest
private class HelloWorldRestServiceTest {
    @IsTest
    static void doGetReturnsHelloWorldMessage() {
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/hello';
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = new RestResponse();

        HelloWorldRestService.HelloResponse response = HelloWorldRestService.doGet();

        System.assertNotEquals(null, response);
        System.assertEquals('Hello World', response.message);
    }
}
