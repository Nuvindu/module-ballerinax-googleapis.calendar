import ballerina/log;
import ballerina/os;
import ballerinax/googleapis.calendar;

configurable string clientId = os:getEnv("CLIENT_ID");
configurable string clientSecret = os:getEnv("CLIENT_SECRET");
configurable string refreshToken = os:getEnv("REFRESH_TOKEN");
configurable string refreshUrl = os:getEnv("REFRESH_URL");

public function main() returns error? {
    calendar:Client calendarClient = check new ({
        auth: {
            clientId: clientId,
            clientSecret: clientSecret,
            refreshToken: refreshToken,
            refreshUrl: refreshUrl
        }
    });

    // create new calendar
    calendar:Calendar calendarResult = check calendarClient->createCalendar({
        summary: "Work Schedule"
    });

    // create new event
    calendar:Event event = check calendarClient->createEvent(<string>calendarResult.id, {
        'start: {
            dateTime: "2023-10-19T09:00:00+05:30",
            timeZone: "Asia/Colombo"
        },
        end: {
            dateTime: "2023-10-19T09:30:00+05:30",
            timeZone: "Asia/Colombo"
        },
        summary: "Project Kickoff Meeting"
    });

    // update event to invite attendees by email
    calendar:Event updatedEvent = check calendarClient->updateEvent(<string>calendarResult.id, <string>event.id, {
        'start: {
            dateTime: "2023-10-19T09:00:00+05:30",
            timeZone: "Asia/Colombo"
        },
        end: {
            dateTime: "2023-10-19T09:30:00+05:30",
            timeZone: "Asia/Colombo"
        },
        summary: "Team Meeting",
        location: "Conference Room",
        description: "Weekly team meeting to discuss project status.",
        attendees: [
            {
                "email": "team-member1@gmail.com"
            },
            {
                "email": "team-member2@gmail.com"
            }
        ]
    });

    // update event to add reminders to send timely notifications to attendees before the meeting
    calendar:Event|error reminderEvent = calendarClient->updateEvent(<string>calendarResult.id, <string>updatedEvent.id, {
        'start: {
            dateTime: "2023-10-19T03:00:00+05:30",
            timeZone: "Asia/Colombo"
        },
        end: {
            dateTime: "2023-10-19T03:30:00+05:30",
            timeZone: "Asia/Colombo"
        },
        reminders: {
            useDefault: false,
            overrides: [
                {method: "popup", minutes: 15},
                {method: "email", minutes: 30}
            ]
        }
    });

    if reminderEvent is error {
        log:printError(reminderEvent.message());
    }

    // create access control rule and assign it to a team member
    calendar:AclRule acl = check calendarClient->createAclRule(<string>calendarResult.id, {
        "scope": {
            "type": "user",
            "value": "team_member@gmail.com"
        },
        "role": "reader"
    });

    // change access control rule
    calendar:AclRule|error response = calendarClient->updateAclRule(<string>calendarResult.id, <string>acl.id, {
        "scope": {
            "type": "user",
            "value": "team_member@gmail.com"
        },
        "role": "writer"
    });
    if response is error {
        log:printError(response.message());
    }
}
