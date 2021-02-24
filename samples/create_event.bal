import ballerina/log;
import ballerinax/googleapis_calendar as calendar;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;
configurable string refreshUrl = ?;
configurable string calendarId = ?;

public function main() {

    calendar:CalendarConfiguration config = {
       oauth2Config: {
           clientId: clientId,
           clientSecret: clientSecret,
           refreshToken: refreshToken,
           refreshUrl: refreshUrl
       }
    };
    calendar:Client calendarClient = new (config);

    calendar:InputEvent event = {
       'start: {
           dateTime:  "2021-02-28T09:00:00+0530"
       },
       end: {
           dateTime:  "2021-02-28T09:00:00+0530"
       },
       summary: "Sample Event"
    };
    calendar:Event|error res = calendarClient->createEvent(calendarId, event);
    if (res is calendar:Event) {
       log:print(res.id);
    } else {
       log:printError(res.message());
    }
}
