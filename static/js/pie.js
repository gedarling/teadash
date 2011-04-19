$.getJSON('/pie', function(data) {  
  var chart = new Highcharts.Chart({
    chart: {
      backgroundColor: '#ffff99',
      renderTo:'pie_graph',
      plotBackgroundColor: '#ffff99',
      plotBorderWidth: null,
      plotShadow: false
    },
    credits: {
      enabled: false
    },    
    title: {
      text: 'Tea Consumption',
      style: {
        color: '#000000',
        fontWeight: 'bold'
      }      
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
      size: '75%',
      innerSize: '15%',      
      data: data
    }]
  });  
});