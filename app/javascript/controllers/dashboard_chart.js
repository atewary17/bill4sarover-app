  document.addEventListener("turbo:load", function () {
    Highcharts.chart('activity-chart', {
      chart: {
        type: 'line'
      },
      title: {
        text: 'Booking Activity'
      },
      xAxis: {
        categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun']
      },
      yAxis: {
        title: { text: 'Number of Bookings' }
      },
      series: [{
        name: 'Bookings',
        data: [29, 71, 106, 129, 144, 176]
      }]
    });
  });
