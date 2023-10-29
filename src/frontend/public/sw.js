self.addEventListener('push', (event) => {
  console.log('[Service Worker]: Received push event', event);

  let notificationData = {};

  try {
    notificationData = event.data.json();
  } catch (error) {
    console.error('[Service Worker]: Error parsing notification data', error);
    notificationData = {
      title: 'No data from server',
      message: 'Displaying default notification',
      icon: '',
      badge: '',
    };
  }

  console.log('[Service Worker]: notificationData', notificationData);

  self.registration.showNotification(
    notificationData.title,
    notificationData
  );
});