using WebPush;

VapidDetails vapidKeys = VapidHelper.GenerateVapidKeys();
Console.WriteLine("Public {0}", vapidKeys.PublicKey);
Console.WriteLine("Private {0}", vapidKeys.PrivateKey);