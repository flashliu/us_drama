import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:auto_orientation/auto_orientation.dart';

// import 'package:html/parser.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    Key key,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final controller = TextEditingController();
  List list = [];
  getListData([String kw = '']) async {
    setState(() {
      list = [];
    });
    var res = await http.post('http://pilipali.cc/index.php/vod/search.html', body: {'wd': kw});
    print('request succuss');
    var doc = parse(res.body);
    var searchList = doc.querySelectorAll('.search-list>.item');
    if (searchList != null) {
      var getId = (String url) {
        return url.replaceAll(RegExp(r'[a-z]'), '').replaceAll(RegExp(r'/'), '').replaceAll(r'.', '');
      };
      setState(() {
        list = searchList.map((item) {
          return {
            'id': getId(item.querySelector('.v-playBtn').attributes['href']),
            'title': item.querySelector('.s_tit strong').text,
            'src': 'http://pilipali.cc' + item.querySelector('.item_pic>img').attributes['src'],
            'description': item.querySelector('.p_intro').text
          };
        }).toList();
      });
    }
  }

  @override
  void initState() {
    getListData();
    super.initState();
  }

  Widget getBody() {
    if (list.length == 0) {
      return Container(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFfb7299)),
        ),
        alignment: Alignment.center,
      );
    }
    return Container(
      child: ListView(
        children: list.map((info) => MediaItem(info: info)).toList(),
      ),
      color: Colors.grey[100],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFfb7299),
        centerTitle: false,
        title: TextField(
          controller: controller,
          cursorColor: Colors.white,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '请输入片名',
            prefixIcon: new Icon(Icons.search, color: Colors.white),
            hintStyle: new TextStyle(color: Colors.white),
            border: InputBorder.none,
          ),
        ),
        actions: <Widget>[
          GestureDetector(
            onTap: () {
              getListData(controller.text);
            },
            child: Container(
              child: Text(
                '搜索',
                style: TextStyle(fontSize: 16.0),
              ),
              padding: EdgeInsets.only(right: 10.0),
              alignment: Alignment.center,
            ),
          ),
        ],
      ),
      body: getBody(),
    );
  }
}

class MediaItem extends StatelessWidget {
  final Map info;
  const MediaItem({Key key, this.info}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: <Widget>[
          Container(
            width: 120.0,
            height: 170.0,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              child: Image.network(info['src'], fit: BoxFit.cover),
            ),
            margin: EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[400],
                  blurRadius: 8.0,
                  spreadRadius: 2.0,
                  offset: Offset(0.0, 6.0),
                )
              ],
            ),
          ),
          Flexible(
            child: Column(
              children: <Widget>[
                Text(
                  info['title'],
                  softWrap: true,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  info['description'],
                  softWrap: true,
                  style: TextStyle(fontSize: 14),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: 10,
                ),
                RaisedButton(
                  child: Container(
                    width: 85,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.play_arrow),
                        Text('立即播放'),
                      ],
                    ),
                  ),
                  color: Color(0xFFfb7299),
                  textColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(5),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MediaDetail(
                              info: info,
                            ),
                      ),
                    );
                  },
                )
              ],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          )
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      padding: EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 10),
      margin: EdgeInsets.only(bottom: 10.0),
      color: Colors.white,
    );
  }
}

class MediaDetail extends StatefulWidget {
  final Map info;
  MediaDetail({Key key, this.info}) : super(key: key);

  _MediaDetailState createState() => _MediaDetailState();
}

class _MediaDetailState extends State<MediaDetail> {
  VideoPlayerController _controller;
  List<Map> playList = [];
  String nid = '1';
  bool loading = false;

  getPlayUrl(String id) async {
    if (_controller != null) {
      setState(() {
        _controller.pause();
        loading = true;
      });
    }
    var res = await http.get('http://pilipali.cc/vod/play/id/${widget.info["id"]}/sid/1/nid/$nid.html');
    var doc = parse(res.body);
    setState(() {
      playList = doc.querySelector('.play-list').children.map((item) {
        var itemDom = item.querySelector('.x_n');
        return {
          'label': itemDom.text,
          'id': itemDom.attributes['href'].split('/')[8].replaceAll('.html', ''),
        };
      }).toList();
    });
    var iplays = doc.querySelectorAll('.iplays>script');
    String playDataStr = iplays[0].text.replaceAll(RegExp(r'var player_data='), '');
    var playData = json.decode(playDataStr);
    var host = 'https://' + playData['url'].toString().split('/')[2];
    var mres = await http.get(playData['url']);
    // var mdoc = parse(mres.body);
    // var data = mdoc.getElementsByTagName('script')[4];
    var matched = RegExp(r"\bvar\s+main(\s+)?=(\s+)?(.*);$", multiLine: true).firstMatch(mres.body);
    var main = matched
        .group(0)
        .replaceAll('var', '')
        .replaceAll(' ', '')
        .replaceAll('main', '')
        .replaceAll('=', '')
        .replaceAll('"', '');
    var rres = await http.get(host + main);
    var rurl = rres.body.split('\n')[2];
    var mainArr = main.split('/');
    var url = host + '/' + mainArr[1] + '/' + mainArr[2] + "/" + rurl;
    bool isFilm = RegExp("^/ppvod").hasMatch(rurl);
    if (isFilm) {
      url = host + rurl;
    }
    print(url);
    _controller = VideoPlayerController.network(url)
      ..initialize().then((_) {
        print('init');
        setState(() {
          loading = false;
        });
        _controller.play();
      }).catchError((error) {
        print(error);
      });
  }

  @override
  void initState() {
    super.initState();
    getPlayUrl(widget.info['id']);
  }

  @override
  void dispose() {
    super.dispose();
    if (_controller != null) _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget player;
    if (_controller != null && _controller.value.initialized && !loading) {
      player = Player(
        controller: _controller,
      );
    } else {
      player = Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFfb7299)),
        ),
      );
    }

    return Scaffold(
      body: Column(children: <Widget>[
        Container(
          child: player,
          height: 300,
          color: Colors.black,
        ),
        Flexible(
          child: GridView.count(
            padding: EdgeInsets.all(15),
            crossAxisSpacing: 10,
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
            children: playList.map((item) {
              var bcColor = Color(0xFFf4f4f4);
              var textColor = Color(0xFF333333);
              if (item['id'] == nid) {
                bcColor = Color(0xFFfb7299);
                textColor = Colors.white;
              }
              return RaisedButton(
                color: bcColor,
                child: Text(
                  item['label'],
                  style: TextStyle(color: textColor),
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () {
                  setState(() {
                    nid = item['id'];
                    getPlayUrl(widget.info['id']);
                  });
                },
              );
            }).toList(),
          ),
        )
      ]),
    );
  }
}

class Player extends StatefulWidget {
  final VideoPlayerController controller;
  Player({Key key, this.controller}) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  double rate = 0;
  VoidCallback listener;
  String getTime(int timestamp) {
    final int hour = (timestamp / 1000 / 3600).floor();
    final int minutes = (timestamp / 1000 / 60 % 60).floor();
    final int seconds = (timestamp / 1000 % 60).floor();
    final String h = hour > 0 ? (hour + 1 <= 10 ? '0$hour' : hour.toString()) + ':' : '';
    final String m = (minutes + 1 <= 10 ? '0$minutes' : minutes.toString()) + ':';
    final String s = seconds > 0 ? seconds + 1 <= 10 ? '0$seconds' : seconds.toString() : '00';

    return h + m + s;
  }

  @override
  void initState() {
    listener = listener = () {
      if (!mounted) {
        return;
      }
      final controller = widget.controller;
      final value = controller.value;
      final int duration = value.duration.inMilliseconds;
      final int position = value.position.inMilliseconds;
      setState(() {
        rate = (position / duration);
      });
    };
    widget.controller.addListener(listener);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget viewPlayer;
    Widget toolsBar;
    final controller = widget.controller;
    final value = controller.value;
    final int duration = value.duration.inMilliseconds;
    final int position = value.position.inMilliseconds;

    viewPlayer = AspectRatio(
      aspectRatio: value.aspectRatio,
      child: VideoPlayer(widget.controller),
    );
    toolsBar = Positioned(
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
            color: Colors.white,
            onPressed: () {
              setState(() {
                value.isPlaying ? controller.pause() : controller.play();
              });
            },
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              getTime(position),
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Flexible(
            child: Slider(
              onChangeStart: (double value) {
                // controller.removeListener(listener);
              },
              onChanged: (double value) {
                setState(() {
                  rate = value;
                });
              },
              onChangeEnd: (double value) {
                final Duration position = controller.value.duration * value;
                controller.seekTo(position);
              },
              value: rate,
              activeColor: Colors.white,
              inactiveColor: Colors.white30,
            ),
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              getTime(duration),
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          IconButton(
            icon: Icon(Icons.fullscreen),
            color: Colors.white,
            onPressed: () {
              AutoOrientation.landscapeRightMode();
              Navigator.push(
                context,
                PageRouteBuilder(pageBuilder: (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) {
                  return Scaffold(
                    body: Player(
                      controller: controller,
                    ),
                  );
                }),
              ).then((v) {
                AutoOrientation.portraitUpMode();
              });
            },
          )
        ],
      ),
      left: 0,
      right: 0,
      bottom: 0,
    );
    return Container(
      child: Stack(
        children: <Widget>[
          Center(
            child: viewPlayer,
          ),
          toolsBar,
          Positioned(
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            top: 20,
          )
        ],
      ),
    );
  }
}
