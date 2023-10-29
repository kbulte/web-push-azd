using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

var vapidPublicKey = builder.Configuration.GetValue<string>("VAP_ID_PUBLIC_KEY");
var vapidPrivateKey = builder.Configuration.GetValue<string>("VAP_ID_PRIVATE_KEY");
builder.Services.AddDbContext<WebPushDb>(opt => opt.UseInMemoryDatabase("PushSubscriptions"));
builder.Services.AddDatabaseDeveloperPageExceptionFilter();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI(options => {
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "v1");
    options.RoutePrefix = "";
});

app.MapGet("/vapid-details", () => $"public: {vapidPublicKey}, private: {vapidPrivateKey}");

app.MapGet("/push-subscriptions", async (WebPushDb db) =>{
    return Results.Ok(await db.PushSubscriptions.Include("Keys").ToListAsync());
})
.WithOpenApi();

app.MapPost("/push-subscriptions", async (PushSubscription pushSubscription, WebPushDb db) =>
{
    pushSubscription.Id = pushSubscription.Endpoint.GetHashCode();
    db.PushSubscriptions.Add(pushSubscription);
    await db.SaveChangesAsync();

    return Results.Created($"/push-subscriptions/{pushSubscription.Id}", pushSubscription);
})
.WithOpenApi();

app.MapDelete("/push-subscriptions/{id}", async (int id, WebPushDb db) =>
{
    if (await db.PushSubscriptions.FindAsync(id) is PushSubscription pushSubscription)
    {
        db.PushSubscriptions.Remove(pushSubscription);
        await db.SaveChangesAsync();
        return Results.NoContent();
    }

    return Results.NotFound();
})
.WithOpenApi();

app.MapPost("/push-subscriptions/notify", async (Notification notification, WebPushDb db) =>
{
    if(notification != null && notification.SubscriptionIds.Length == 1){
        var id = int.Parse(notification.SubscriptionIds.First());
        if (db.PushSubscriptions.Include("Keys").Single(x => x.Id == id) is PushSubscription pushSubscription){
            pushSubscription.Notify(notification, vapidPublicKey, vapidPrivateKey);
            return Results.NoContent();
        }

        return Results.NotFound();
    }
   
   return Results.BadRequest();

})
.WithOpenApi();

app.MapPost("/push-subscriptions/notify-all", async (Notification notification, WebPushDb db) =>
{
    var pushSubscriptions = await db.PushSubscriptions.Include("Keys").ToListAsync();
    foreach (var pushSubscription in pushSubscriptions)
    {
        pushSubscription.Notify(notification, vapidPublicKey, vapidPrivateKey);
    }
   
    return Results.NoContent();
})
.WithOpenApi();


app.Run();