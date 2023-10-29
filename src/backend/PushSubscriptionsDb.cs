using Microsoft.EntityFrameworkCore;

class WebPushDb : DbContext
{
    public WebPushDb(DbContextOptions<WebPushDb> options)
        : base(options) { }

    public DbSet<PushSubscription> PushSubscriptions => Set<PushSubscription>();
}