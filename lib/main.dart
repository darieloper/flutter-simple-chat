import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(
        title: 'Simple Chat',
        channel: IOWebSocketChannel.connect(
            'wss://simple-web-socket.herokuapp.com/'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final WebSocketChannel channel;

  MyHomePage({Key key, @required this.title, @required this.channel})
      : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class MessageData {
  String data;
  bool me;
  DateTime arrived;

  MessageData({this.data, this.me, this.arrived});
}

class DataToSend {
  String message;
  String uuid;

  DataToSend({this.message, this.uuid});
}

class _MyHomePageState extends State<MyHomePage> {
  String uuid;
  List<MessageData> messages = new List();
  TextEditingController _controller = TextEditingController();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.channel.stream.listen((message) {
      reactToMessage(message);
    });
  }

  void reactToMessage(String message) {
    Map<String, dynamic> decoded = jsonDecode(message);
    print(message);
    switch (decoded['type']) {
      case 'identifier':
        this.setState(() {
          uuid = decoded['data'].toString();
        });
        print('connected ' + uuid);
        break;

      case 'message':
        this.setState(() {
          messages.add(MessageData(
              data: decoded['data'],
              me: decoded['uuid'] == uuid,
              arrived: DateTime.now()));
          print(messages.last);
        });
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut);
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('images/wallpaper2.jpg'),
                    fit: BoxFit.cover)),
            child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                              child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                var msg = messages[index];

                                return MessageBubble(msg: msg);
                              },
                            ),
                          )),
                          Container(
                            height: 60,
                            padding: EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Container(
                                  padding: EdgeInsets.only(
                                      top: 0, bottom: 5, left: 10, right: 10),
                                  margin: EdgeInsets.only(right: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: TextFormField(
                                    controller: _controller,
                                    maxLines: 1,
                                    decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(
                                            top: 10, bottom: 10),
                                        border: InputBorder.none,
                                        hintText: 'Type your message'),
                                  ),
                                )),
                                Container(
                                  padding: EdgeInsets.zero,
                                  width: 32,
                                  child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        Icons.send,
                                        color: Colors.deepOrange,
                                        size: 32,
                                      ),
                                      onPressed: () => _sendMessage()),
                                ),
                              ],
                            ),
                          ),
                        ])))));
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      Map<String, dynamic> data = {'data': _controller.text, 'uuid': uuid};
      widget.channel.sink.add(jsonEncode(data));

      setState(() {
        _controller.text = "";
      });
    }
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final MessageData msg;
  final DateTime arrived;

  MessageBubble({Key key, this.msg, this.arrived}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String datePart = msg.arrived.hour >= 12 ? 'pm' : 'am';
    int hour = msg.arrived.hour > 12 ? msg.arrived.hour - 12 : msg.arrived.hour;
    String minutes = msg.arrived.minute.toString().padLeft(2, '0');
    if (hour == 0) {
      hour = 12;
    }
    String format = "${hour.toString().padLeft(2, '0')}:$minutes $datePart";

    return Padding(
        padding: EdgeInsets.only(bottom: 10, left: 10, right: 10),
        child: Align(
          alignment: msg.me ? Alignment.topRight : Alignment.topLeft,
          child: ClipPath(
            clipper: BubbleShape(!msg.me),
            child: Container(
                width: msg.data.length > 20
                    ? MediaQuery.of(context).size.width * 0.6
                    : null,
                padding: EdgeInsets.fromLTRB(
                    msg.me ? 10 : 20, 10, msg.me ? 20 : 10, 10),
                decoration: BoxDecoration(
                  color:
                      msg.me ? Colors.orange.shade300 : Colors.green.shade300,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(msg.data),
                    Container(
                      width: 52,
                      padding: EdgeInsets.only(top: 5, left: 0),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          format,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              color: Colors.grey.shade800, fontSize: 12),
                        ),
                      ),
                    )
                  ],
                )),
          ),
        ));
  }
}

class BubbleShape extends CustomClipper<Path> {
  final bool leftCorner;

  BubbleShape(this.leftCorner);

  @override
  Path getClip(Size size) {
    return this.leftCorner ? drawFromLeft(size) : drawFromRight(size);
  }

  Path drawFromRight(Size size) {
    var path = Path();
    path.moveTo(10, 0);
    path.arcToPoint(Offset(0.0, 10),
        radius: Radius.circular(10), clockwise: false);
    path.lineTo(0.0, size.height - 10);
    path.arcToPoint(Offset(10, size.height),
        radius: Radius.circular(10), clockwise: false);
    path.lineTo(size.width - 20, size.height);
    path.arcToPoint(Offset(size.width - 10, size.height - 10),
        radius: Radius.circular(10), clockwise: false);
    path.lineTo(size.width - 10, 15);
    path.lineTo(size.width, 0);

    return path;
  }

  Path drawFromLeft(Size size) {
    var path = Path();
    path.moveTo(size.width - 10, 0);
    path.arcToPoint(Offset(size.width, 10), radius: Radius.circular(10));
    path.lineTo(size.width, size.height - 10);
    path.arcToPoint(Offset(size.width - 10, size.height),
        radius: Radius.circular(10));
    path.lineTo(20, size.height);
    path.arcToPoint(Offset(10, size.height - 10), radius: Radius.circular(10));
    path.lineTo(10, 15);
    path.lineTo(0, 0);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return oldClipper != this;
  }
}

extension ColorExtension on String {
  toColor() {
    var hexColor = this.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }
}
