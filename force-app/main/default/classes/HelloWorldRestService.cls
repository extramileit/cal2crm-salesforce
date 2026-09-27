@RestResource(urlMapping='/hello/*')
global with sharing class HelloWorldRestService {
    global class HelloResponse {
        public String message;
    }

    @HttpGet
    global static HelloResponse doGet() {
        HelloResponse response = new HelloResponse();
        response.message = 'Hello World';
        return response;
    }
}
