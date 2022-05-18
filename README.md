Creates GPX tracks for all strava activities of a user. Uses streams api v3 to reconstruct the uploaded tracks.

1. Checkout repo
2. Call www.strava.com/oauth/authorize?client_id=1924&response_type=code&redirect_uri=http://localhost/exchange_token&approval_prompt=force&scope=view_private in your browser.
3. Copy the value of 'code' from the response and insert it in a file named 'access_token.txt' directly in the checked out repo
4. Call strava.rb

Reconstructed GPX tracks from all your activities will be placed in
the current directory. Due to the restrictions of the strava V3 api
these is *not* your original uploaded gpx file. It is reconstructed
from so called streams, see: https://strava.github.io/api/v3/streams/

The created GPX files are named by the name of the original uploaded
file -- if the activity was uploaded via the strava app this is a
woozily hash -- and the start date and time of the activity.


