$.getJSON('/pie', function(data) {
  var fields = [];
  var labels = [];
  $.each(data, function(idx,value){
      labels.push('%%.%% - ' + value[0]);
      fields.push(value[1]);
  });
  
  var r = Raphael('pie_graph');
  r.g.txtattr.font = "12px 'Fontin Sans', Fontin-Sans, sans-serif";
  r.g.text(200, 10, "Tea Consumption").attr({"font-size": 20});
  
  var pie = r.g.piechart(
    200,
    200,
    160,
    fields,
    {
      legend: labels,
      legendpos: "east"
    }
  );
  
  pie.hover(function () {
    this.sector.stop();
    this.sector.scale(1.1, 1.1, this.cx, this.cy);
    if (this.label) {
      this.label[0].stop();
      this.label[0].scale(1.5);
      this.label[1].attr({"font-weight": 800});
    }
  }, function () {
    this.sector.animate({scale: [1, 1, this.cx, this.cy]}, 500, "bounce");
    if (this.label) {
      this.label[0].animate({scale: 1}, 500, "bounce");
      this.label[1].attr({"font-weight": 400});
    }
  });
});