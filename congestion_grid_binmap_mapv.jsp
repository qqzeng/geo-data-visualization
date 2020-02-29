<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%
  String path = request.getContextPath();
  String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <base href="<%=basePath%>">

  <title>拥堵网格可视化</title>
  <style type="text/css">
    html, body {
      width: 100%;
      height: 100%;
      margin: 0;
      padding: 0;
      overflow: hidden;
    }
    #map {
      width: 100%;
      height: 100%;
    }
  </style>
  <meta http-equiv="pragma" content="no-cache">
  <meta http-equiv="cache-control" content="no-cache">
  <meta http-equiv="expires" content="0">
  <meta http-equiv="keywords" content="keyword1,keyword2,keyword3">
  <meta http-equiv="description" content="This is my page">
  <script type="text/javascript" src="<%=basePath%>/build/jquery-1.10.2.min.js"></script>
</head>

<body>
<input type="button" value="显示下一时间片的拥塞情况" onclick="display_interval_congestion();"/>
<input type="button" value="显示上一时间片的拥塞情况" onclick="display_last_interval_congestion();"/>
<input type="button" value="清除当前拥塞情况" onclick="clear_interval_congestion();"/>
<div id="time_interval" style="float: left;margin-right: 50px;margin-top: 3px;"></div>
<div id="map"></div>
<canvas id="canvas" style="width: 100px; height: 200px"></canvas>
<script type="text/javascript" src="http://api.map.baidu.com/api?v=2.0&ak=SGZAQcGREz9ugRxt9eWnn7nHynec9lRb"></script>
<script type="text/javascript" src="build/jquery-1.10.2.min.js"></script>
<script type="text/javascript" src="build/mapv.js"></script>
<script type="text/javascript">
    // 这个文件需借助动态web应用来使用，因为使用了ajax获取本地服务器（本地）数据
    cur_part_no = "1";
    url = "data/sfba/part"+cur_part_no+"/grid32/visual_data/congestion_grid_clustering/";
    var time_interval_index = -1;
    time_interval_tiny = ["0700-0720", "0720-0740", "0740-0800", "0800-0820", "0820-0840", "0840-0900",
        "1700-1720", "1720-1740", "1740-1800", "1800-1820", "1820-1840", "1840-1900"];
    time_interval = ["0600-0800", "0800-1000", "1600-1800", "1800-2000"];
    time_interval_large = ["0600-1000", "1100-1400", "1600-2000"];
    cur_time_interval = time_interval_tiny;

    // reference: https://github.com/huiyan-fe/mapv/blob/master/API.md
    var map = new BMap.Map("map", {
        enableMapClick: false,
    });
    map.centerAndZoom(new BMap.Point(-122.435534,37.755495), 14);
    map.enableScrollWheelZoom(true);
    map.addControl(new BMap.ScaleControl());
    map.setMapStyle({
        style: 'normal' // http://lbsyun.baidu.com/custom/list.htm
    });

    // 保证网格大小与地图标尺大小一致
    zoom_size_dict = {14:30, 15:60, 16:120, 17:240, 18:480, 19:960};
    map.addEventListener("zoomend", function(evt){
        options.size = zoom_size_dict[this.getZoom()];
        console.log("current zoom is " + this.getZoom() + ", and current size is " + options.size);
        if (typeof mapvLayer != "undefined") {
            mapvLayer.update(options);
        }
    });

    var lngExtent = [-122.52, -122.38];
    var latExtent = [37.70, 37.81];

    var geo_grid_width = 32;
    var geo_grid_height = 32;

    var geo_grid_unit_lon = (lngExtent[1] - lngExtent[0]) / geo_grid_width;
    var geo_grid_unit_lat = (latExtent[1] - latExtent[0]) / geo_grid_height;

    var options = {
        fillStyle: 'rgba(55, 50, 250, 0.8)',
        shadowColor: 'rgba(255, 250, 50, 1)',
        shadowBlur: 20,
        size: 30,
        globalAlpha: 0.3,
        label: {
            show: true,
            fillStyle: 'white',
            // shadowColor: 'yellow',
            font: '12px Arial',
            // shadowBlur: 10
        },
        gradient: { 0.15: "rgb(0,0,255)", 0.35: "rgb(0,255,0)", 0.75: "yellow", 1.0: "rgb(255,0,0)"},
        draw: 'grid', // heapmap
        max: 50,
        methods: {
            click: function (item) {
                alert(item.count);
                console.log(item);
            }
        }
    };

    function get_next_time_interval_congestion_points(interval_step) {
        time_interval_index = (time_interval_index + interval_step);
        if (time_interval_index <= -1) {
            time_interval_index = cur_time_interval.length - 1;
        } else {
            time_interval_index = time_interval_index % cur_time_interval.length;
        }
        var points = [];
        var load_data = function () {
            <%--$.ajaxSettings.async = false;--%>
            <%--$.getJSON("<%=basePath%>"+url+time_interval[time_interval_index], function (data) {--%>
                <%--points = data;--%>
            <%--});--%>
            $.ajax({
                url: "<%=basePath%>"+url+cur_time_interval[time_interval_index]+".json",
                data: "",
                async: false,
                success: function (data) {
                    points = data;
                },
                error: function(info) {
                    console.log("Fail to load congestion data " + cur_time_interval[time_interval_index])
                },
                dataType: "json"
            });
        };
        load_data();
        console.log(points.length)
        return points;
    }

    function build_next_time_interval_congestion_data(points) {
        var data = [];
        for (var i = 0; i < points.length; i++) {
            data.push({
                geometry: {
                    type: 'Point',
                    coordinates: [points[i].lng, points[i].lat]
                    // coordinates: [cityCenter.lng - 2 + Math.random() * 4, cityCenter.lat - 2 + Math.random() * 4]
                },
                count: points[i].count
            });
        }
        return data;
    }

    var mapvLayer;
    function build_next_time_interval_congestion_data_maplayer(data) {
        if (typeof mapvLayer != "undefined") {
            console.log("delete old mapvLayer first!");
            mapvLayer.destroy();
            delete mapvLayer;
        }
        var dataSet = new mapv.DataSet(data);
        mapvLayer = new mapv.baiduMapLayer(map, dataSet, options);
        return mapvLayer;
    }

    function display_interval_congestion() {
        points = get_next_time_interval_congestion_points(1);
        data = build_next_time_interval_congestion_data(points);
        build_next_time_interval_congestion_data_maplayer(data);
        $("#time_interval").text("当前显示时间片为：" + cur_time_interval[time_interval_index]);
        console.log("current zoom is " + map.getZoom() + ", and current size is " + options.size);
    }

    function display_last_interval_congestion() {
        points = get_next_time_interval_congestion_points(-1);
        data = build_next_time_interval_congestion_data(points);
        build_next_time_interval_congestion_data_maplayer(data);
        $("#time_interval").text("当前显示时间片为：" + cur_time_interval[time_interval_index]);
        console.log("current zoom is " + map.getZoom() + ", and current size is " + options.size);
    }

    function clear_interval_congestion() {
        if (typeof mapvLayer != "undefined") {
            console.log("delete old mapvLayer first!");
            mapvLayer.destroy();
            delete mapvLayer;
        }
        console.log("Clear mapvLayer");
    }

</script>
</body>
</html>
