// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;

class EventStream {
    private Event[] currentEntries = [];
    private int index = 0;
    private final http:Client httpClient;
    private string? pageToken = ();
    private final string calendarId;
    private final ClientOAuth2ExtensionGrantHandler clientHandler;
    private final EventFilterCriteria? optional;
    private final string? userAccount;

    isolated function init(http:Client httpClient, string calendarId,  ClientOAuth2ExtensionGrantHandler clientHandler,
                            EventFilterCriteria? optional, string? userAccount) returns error? {
        self.httpClient = httpClient;
        self.calendarId = calendarId;
        self.clientHandler = clientHandler;
        self.optional = optional;
        self.userAccount = userAccount;
        self.currentEntries = check self.fetchEvents();
        return;
    }

    public isolated function next() returns @tainted record {| Event value; |}|error? {
        if (self.index < self.currentEntries.length()) {
            record {| Event value; |} event = {value: self.currentEntries[self.index]};
            self.index += 1;
            return event;
        }
        if (self.pageToken is string) {
            self.index = 0;
            self.currentEntries = check self.fetchEvents();
            record {| Event value; |} event = {value: self.currentEntries[self.index]};
            self.index += 1;
            return event;
        }
        return;
    }

    isolated function fetchEvents() returns @tainted Event[]|error {
        string path = <@untainted>prepareUrlWithEventsOptionalParams(self.calendarId, pageToken = self.pageToken, 
        optional = self.optional);
        map<string> headerMap = check setHeaders(self.clientHandler, self.userAccount);
        http:Response httpResponse = check self.httpClient->get(path, headerMap);
        json resp = check checkAndSetErrors(httpResponse);
        EventResponse|error res = resp.cloneWithType(EventResponse);
        if (res is EventResponse) {
            self.pageToken = res?.nextPageToken;
            return res.items;
        } else {
            return error(ERR_EVENT_RESPONSE, res);
        }
    }
}

class CalendarStream {
    private Calendar[] currentEntries = [];
    int index = 0;
    private final http:Client httpClient;
    private CalendarsToAccess? optional;
    private string? pageToken = ();
    private ClientOAuth2ExtensionGrantHandler clientHandler;
    private final string? userAccount;

    isolated function init(http:Client httpClient, ClientOAuth2ExtensionGrantHandler clientHandler,
                            CalendarsToAccess? optional = (), string? userAccount = ()) returns error? {
        self.httpClient = httpClient;
        self.optional = optional;
        self.clientHandler = clientHandler;
        self.userAccount = userAccount;
        self.currentEntries = check self.fetchCalendars();
        return;
    }

    public isolated function next() returns @tainted record {| Calendar value; |}|error? {
        if (self.index < self.currentEntries.length()) {
            record {| Calendar value; |} calendar = {value: self.currentEntries[self.index]};
            self.index += 1;
            return calendar;
        }

        if (self.pageToken is string) {
            self.index = 0;
            self.currentEntries = check self.fetchCalendars();
            record {| Calendar value; |} calendar = {value: self.currentEntries[self.index]};
            self.index += 1;
            return calendar;
        }
        return;
    }

    isolated function fetchCalendars() returns @tainted Calendar[]|error {
        string path = <@untainted>prepareUrlWithCalendarOptional(self.pageToken, self.optional);
        map<string> headerMap = check setHeaders(self.clientHandler, self.userAccount);
        http:Response httpResponse = check self.httpClient->get(path, headerMap);
        json resp = check checkAndSetErrors(httpResponse);
        CalendarResponse|error res = resp.cloneWithType(CalendarResponse);
        if (res is CalendarResponse) {
            self.pageToken = res?.nextPageToken;
            return res.items;
        } else {
            return error(ERR_CALENDAR_RESPONSE, res);
        }
    }
}
