<%--
  Created by IntelliJ IDEA.
  User: GEORGE-pc
  Date: 2020/2/29
  Time: 15:07
  To change this template use File | Settings | File Templates.
--%>
<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%
    String path = request.getContextPath();
    String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
    <script type="text/javascript" src="http://api.map.baidu.com/api?v=2.0&ak=SGZAQcGREz9ugRxt9eWnn7nHynec9lRb"></script>
    <script type="text/javascript" src="http://api.map.baidu.com/library/Heatmap/2.0/src/Heatmap_min.js"></script>
    <script type="text/javascript" src="build/jquery-1.10.2.min.js"></script>
    <title>拥堵传播模式热力图展示</title>
    <style type="text/css">
        ul,li{list-style: none;margin:0;padding:0;float:left;}
        html{height:100%}
        body{height:100%;margin:0px;padding:0px;font-family:"微软雅黑";}
        #container{height:95%;width:100%;}
        #r-result{width:100%;}
    </style>
</head>
<body>
<div id="container" ></div>
<div id="r-result">
    <div id="interval" style="float: left;margin-right: 10px;"></div>
    <div id="progress" style="float: left;margin-right: 10px;"></div>
    <input type="button"  onclick="closeHeatmap();" value="关闭拥塞传播的热力图图示"/>
    <input type="button"  onclick="display_next_interval_heatmaps();" value="显示下一时间片的拥塞传播的热力图示集合"/>
    <input type="button"  onclick="display_next_heatmap();" value="显示下一拥塞传播的热力图示"/>
    <input type="button"  onclick="display_last_interval_heatmaps();" value="显示上一时间片的拥塞传播情热力图示集合"/>
    <input type="button"  onclick="display_last_heatmap();" value="显示上一拥塞传播情热力图示"/>
    <input type="button"  onclick="next_day();" value="转到下一天"/>
</div>
</body>
</html>
<script type="text/javascript">

    // 这个文件需借助动态web应用来使用，因为使用了ajax获取本地服务器（本地）数据
    cur_part_no = 4;
    url_cpp = "data/sfba/part"+cur_part_no+"/grid32/visual_data/congestion_propagation_pattern_data/";
    url_tg = "data/sfba/part"+cur_part_no+"/grid32/visual_data/transition_grid_data/";
    time_interval_large = ["0600-1000", "1700-2100"];


    function get_next_time_interval_congestion_propagation_data(interval_step) {
        cpp_interval_index = (cpp_interval_index + interval_step);
        if (cpp_interval_index <= -1) {
            cpp_interval_index = time_interval_large.length - 1;
        } else {
            cpp_interval_index = cpp_interval_index % time_interval_large.length;
        }
        var interval_points = [];
        var load_data = function () {
            $.ajax({
                url: "<%=basePath%>"+url_cpp+"cpp_"+time_interval_large[cpp_interval_index]+".json",
                data: "",
                async: false,
                success: function (data) {
                    interval_points = data;
                },
                error: function(info) {
                    console.log("Fail to load congestion propagation data " + time_interval_large[cpp_interval_index])
                },
                dataType: "json"
            });
        };
        load_data();
        return interval_points;
    }

    function get_next_time_interval_transition_congestion_grid_data(interval_step) {
        tg_interval_index = (tg_interval_index + interval_step);
        if (tg_interval_index <= -1) {
            tg_interval_index = time_interval_large.length - 1;
        } else {
            tg_interval_index = tg_interval_index % time_interval_large.length;
        }
        var interval_points = [];
        var load_data = function () {
            $.ajax({
                url: "<%=basePath%>"+url_tg+"tg_"+time_interval_large[tg_interval_index]+".json",
                data: "",
                async: false,
                success: function (data) {
                    interval_points = data;
                },
                error: function(info) {
                    console.log("Fail to load congestion propagation data " + time_interval_large[tg_interval_index])
                },
                dataType: "json"
            });
        };
        load_data();
        return interval_points;
    }

    var map = new BMap.Map("container");
    // var point = new BMap.Point(-122.45, 37.755);
    var point = new BMap.Point(-122.420586,37.78767);
    map.centerAndZoom(point, 14);
    map.enableScrollWheelZoom(true);
    map.addControl(new BMap.ScaleControl());

    if(!isSupportCanvas()){
        alert('热力图目前只支持有canvas支持的浏览器,您所使用的浏览器不能使用热力图功能~')
    }
    //详细的参数,可以查看heatmap.js的文档 https://github.com/pa7/heatmap.js/blob/master/README.md
    //参数说明如下:
    /* visible 热力图是否显示,默认为true
     * opacity 热力的透明度,1-100
     * radius 势力图的每个点的半径大小
     * gradient  {JSON} 热力图的渐变区间 . gradient如下所示
     *  {
            .2:'rgb(0, 255, 255)',
            .5:'rgb(0, 110, 255)',
            .8:'rgb(100, 0, 255)'
        }
        其中 key 表示插值的位置, 0~1.
            value 为颜色值.
     */
    var cpp_interval_index = -1;
    var tg_interval_index = -1;
    var cpp_index = -1;
    var tg_index = -1;
    var interval_points;
    var tg_interval_points;
    var points;
    var tg_points;
    var options = {
        "radius":25
    };

    heatmapOverlay = new BMapLib.HeatmapOverlay(options); // 14->25, 15->50, 16->90
    map.addOverlay(heatmapOverlay);

    zoom_icon_dict = {18:["image/position-2-1.png", 64], 17:["image/position-2-1.png", 64], 16:["image/position-2-2.png", 48],
        15:["image/position-2.png", 32], 14:["image/position-2-3.png", 16], 13:["image/position-2-3.png", 16]};
    // 放大到 14 级
    var icon = new BMap.Icon(
        'image/position-2-3.png',
        new BMap.Size(16, 16)
    );
    // 放大到 15 级
    // var icon = new BMap.Icon(
    //     'image/position-2.png',
    //     new BMap.Size(32, 32)
    // );
    // 放大到 16 级
    // var icon = new BMap.Icon(
    //     'image/position-2-2.png',
    //     new BMap.Size(48, 48)
    // );

    // 保证网格大小与地图标尺大小一致
    zoom_size_dict = {13:12, 14:25, 15:50, 16:90, 17:200};
    map.addEventListener("zoomend", function(evt){
        options.radius = zoom_size_dict[this.getZoom()];
        console.log("current zoom is " + this.getZoom() + ", and current radius is " + options.radius);
        if ((this.getZoom() < 13 || this.getZoom() > 17) || points == "undefined" || cpp_index == -1) {
            return
        }
        if (typeof heatmapOverlay != "undefined") {
            heatmapOverlay.toggle();
            heatmapOverlay = new BMapLib.HeatmapOverlay({"radius":zoom_size_dict[this.getZoom()]}); // 14->25, 15->50, 16->90
            map.addOverlay(heatmapOverlay);
            openHeatmap();
        }

        icon_png = zoom_icon_dict[this.getZoom()][0];
        icon_size = zoom_icon_dict[this.getZoom()][1];
        icon = new BMap.Icon(
            icon_png,
            new BMap.Size(icon_size, icon_size)
        );
        showMarker();
    });

    zoom_offset_dict = {13:0.0014, 14:0.0014, 15:0.0012, 16:0.0010, 17:0.0008};
    var marker_memo = new Array();
    function showMarker() {
        while (marker_memo.length > 0) {
            marker = marker_memo.pop();
            map.removeOverlay(marker)
        }
        for (var i = 0; i < tg_points.length; i++) {
            mk = tg_points[i];
            // markerPosOffset = 0.0012 // 放大到 15 级
            // markerPosOffset = 0.0010; // 放大到 16 级
            markerPosOffset = zoom_offset_dict[map.getZoom()];
            var mostDensityPoint = new BMap.Point(mk['location'][0],mk['location'][1]+markerPosOffset);
            var marker = new BMap.Marker(mostDensityPoint, {icon: icon});
            map.addOverlay(marker);
            marker_memo.push(marker)
        }
    }

    function openHeatmap(){
        heatmapOverlay.setDataSet({data:points,max:10});
        heatmapOverlay.show();
        showMarker()
    }

    function display_next_interval_heatmaps() {
        interval_points = get_next_time_interval_congestion_propagation_data(1);
        tg_interval_points = get_next_time_interval_transition_congestion_grid_data(1);
        console.log(interval_points.length);
        console.log(tg_interval_points.length);

        $("#interval").text("当前时间片为：" + time_interval_large[tg_interval_index]);
        tg_index =-1;
        cpp_index = -1;
        display_next_heatmap();
    }

    function display_last_interval_heatmaps() {
        interval_points = get_next_time_interval_congestion_propagation_data(-1);
        tg_interval_points = get_next_time_interval_transition_congestion_grid_data(-1);
        console.log(interval_points.length);
        console.log(tg_interval_points.length);

        $("#interval").text("当前时间片为：" + time_interval_large[tg_interval_index]);

        display_last_heatmap();
    }

    function patch() {
        console.log("points length is " + points.length);
        for (var i = 0; i < tg_points.length; i++) {
            tg_p = tg_points[i];
            exists = false;
            for (var j = 0; j < points.length; j++) {
                if (tg_p["location"][0] == points[j]["lng"] && tg_p["location"][1] == points[j]["lat"]) {
                    exists = true;
                }
            }
            if (!exists) {
                points.push({"count":20, "lat":tg_p["location"][1], "lng":tg_p["location"][0]});
            }
        }
        console.log("points length is " + points.length);
    }

    function display_next_heatmap() {
        tg_index = (tg_index + 1) % tg_interval_points.length;
        tg_points = tg_interval_points[tg_index];

        cpp_index = (cpp_index + 1) % interval_points.length;
        points = interval_points[cpp_index];

        patch();
        console.log(tg_points.length);
        console.log(points.length);

        openHeatmap();

        $("#progress").text("day" + (cur_part_no+24)+" "+ tg_index+"/"+(tg_interval_points.length-1));

    }

    function display_last_heatmap() {
        tg_index = (tg_index -1);
        if (tg_index <= -1) {
            tg_index = tg_interval_points.length - 1;
        }
        tg_points = tg_interval_points[tg_index];

        cpp_index = (cpp_index -1);
        if (cpp_index <= -1) {
            cpp_index = interval_points.length - 1;
        }
        points = interval_points[cpp_index];

        patch();
        console.log(tg_points.length);
        console.log(points.length);

        openHeatmap();
        $("#progress").text("day" + (cur_part_no+24)+" "+ tg_index+"/"+(tg_interval_points.length-1));

    }

    function next_day() {
        cur_part_no = (cur_part_no + 1) % 8;
        url_cpp = "data/sfba/part"+cur_part_no+"/grid32/visual_data/congestion_propagation_pattern_data/";
        url_tg = "data/sfba/part"+cur_part_no+"/grid32/visual_data/transition_grid_data/";
        display_next_interval_heatmaps()
    }

    function closeHeatmap(){
        heatmapOverlay.hide();
    }

    closeHeatmap();

    function setGradient(){
        /*:
        {
            0:'rgb(102, 255, 0)',
            .5:'rgb(255, 170, 0)',
            1:'rgb(255, 0, 0)'
        }*/
        var gradient = {};
        var colors = document.querySelectorAll("input[type='color']");
        colors = [].slice.call(colors,0);
        colors.forEach(function(ele){
            gradient[ele.getAttribute("data-key")] = ele.value;
        });
        heatmapOverlay.setOptions({"gradient":gradient});
    }
    function isSupportCanvas(){
        var elem = document.createElement('canvas');
        return !!(elem.getContext && elem.getContext('2d'));
    }
</script>
