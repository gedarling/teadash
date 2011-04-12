$.getJSON('/pie', function(data) {  
  var chart = new Highcharts.Chart({
    chart: {
      renderTo:'pie_graph',
      plotBackgroundColor: null,
      plotBorderWidth: null,
      plotShadow: false
    },
    title: {
      text: 'Tea Consumption'
    },
    tooltip: {
      formatter: function() {
        return '<b>'+ this.point.name +'</b>: '+ this.y +' %';
      }
    },
    plotOptions: {
      pie: {
        allowPointSelect: true,
        cursor: 'pointer',
        dataLabels: {
          enabled: true,
          color: '#000000',
          connectorColor: '#000000',
          formatter: function() {
            return '<b>'+ this.point.name +'</b>: '+ this.y +' %';
          }
        }
      }
    },
     series: [{
      type: 'pie',
      data: data
    }]
  });  
});