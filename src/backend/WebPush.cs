
using Newtonsoft.Json;
using WebPush;

static class WebPushExtensions
    {
        public async static void Notify(this PushSubscription pushSubscription, Notification notification, string publicKey, string privateKey){
            var pushEndpoint = pushSubscription.Endpoint;
            var p256dh = pushSubscription.Keys.P256dh;
            var auth = pushSubscription.Keys.Auth;

            var subject = "mailto:kris.bulte@katoennatie.com";

            var subscription = new WebPush.PushSubscription(pushEndpoint, p256dh, auth);
            var vapidDetails = new VapidDetails(subject, publicKey, privateKey);
            var webPushClient = new WebPushClient();

            try
            {
                await webPushClient.SendNotificationAsync(subscription, JsonConvert.SerializeObject(notification), vapidDetails);
            }
            catch (WebPushException exception)
            {
                Console.WriteLine($"Http STATUS code{exception.StatusCode}");
            }
        }
    }
