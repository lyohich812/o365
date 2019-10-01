class OutlookController < ApplicationController
    def getAuthcode
        endpoint = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?
            client_id=846dd872-d7d0-443b-9919-f2e060e19031
            &response_type=code
            &redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fauthorize
            &response_mode=query
            &scope=openid%20profile%20offline_access%20https%3A%2F%2Fgraph.microsoft.com%2Fuser.read%20https%3A%2F%2Fgraph.microsoft.com%2Fmail.read%20https%3A%2F%2Fgraph.microsoft.com%2Fcontacts.read%20https%3A%2F%2Fgraph.microsoft.com%2Fcalendars.read
            &state=12345"
         
    end

    def updateData
        @auth_code = params[:code]

        client = OAuth2::Client.new(
            CLIENT_ID, CLIENT_SECRET,
            site: "https://login.microsoftonline.com",
            authorize_url: "/common/oauth2/v2.0/authorize",
            token_url: "/common/oauth2/v2.0/token"
            )

        authorize_url = "http://localhost:3000/authorize"
            
        mainToken = client.auth_code.get_token(
        auth_code,
        redirect_uri: authorize_url,
        scope: SCOPES.join(' ')
        )
        #initialize once through auth_code
        
        if mainToken.expired?
            mainToken=mainToken.refresh!
            #kak variant create job to .refresh! once at hour
        
            token_hash = mainToken.to_hash

            


            token = OAuth2::AccessToken.from_hash(client, token_hash)

            access_token = token.token

            token = access_token

            callback = Proc.new do |r|
                r.headers['Authorization'] = "Bearer #{token}"
            end

            graph = MicrosoftGraph.new(base_url: 'https://graph.microsoft.com/v1.0',
                                cached_metadata_file: File.join(MicrosoftGraph::CACHED_METADATA_DIRECTORY, 'metadata_v1.0.xml'),
                                &callback)
            
            
            @events = graph.me.events.order_by('start/dateTime asc')
            @events.each do |event|
                event = event.to_json
                event_hash = JSON.parse(event)
                new_record = Event.new(event_hash)
                old_record = Event.find_by(id: new_record.id)
                if old_record == nil
                    new_record.save
                else
                    old_record.destroy
                    new_record.save
                end
            end
    end
end

#rails generate model Event id:string created_date_time:timestamp last_modified_date_time:datetime change_key:string categories:string original_start_time_zone:string original_end_time_zone:string response_status:string i_cal_u_id:string reminder_minutes_before_start:integer is_reminder_on:boolean has_attachments:boolean subject:string body:string body_preview:string importance:string sensitivity:string start:string end:string location:string is_all_day:boolean is_cancelled:boolean is_organizer:boolean recurrence:string response_requested:boolean series_master_id:string show_as:string type:string attendees:string organizer:string web_link:string
