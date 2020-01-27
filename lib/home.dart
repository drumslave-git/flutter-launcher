import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter_widgets/flutter_widgets.dart';

final double scrollHeight = 60.0;

class MyHomePage extends StatefulWidget {
  MyHomePage();

  @override
  createState() => _MyHomePageState();
}

Future<List<Application>> getApps() async {
  return await DeviceApps.getInstalledApplications(
      onlyAppsWithLaunchIntent: true,
      includeSystemApps: true,
      includeAppIcons: true);
}

class _MyHomePageState extends State<MyHomePage> {
  List<Application> _apps = new List();
  List<Map> _letters = new List();
  ItemScrollController _controller;

  @override
  void initState() {
    _controller = ItemScrollController();
    super.initState();

    getApps().then((data) {
      data.sort(
          (a, b) => a.appName.toUpperCase().compareTo(b.appName.toUpperCase()));
      setState(() {
        _apps = data;
        _letters = lettersFromApps(_apps);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (_apps.length == 0) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else {
          List<Map> letters = new List();
          List<String> addedLetters = new List();
          int appIdx = 0;
          _apps.forEach((app) {
            final firstLetter = app.appName[0].toUpperCase();
            if (!addedLetters.contains(firstLetter)) {
              addedLetters.add(firstLetter);
              letters.add({'letter': firstLetter, 'top': appIdx * (50.0 + 8)});
            }
            appIdx++;
          });
          letters.sort((a, b) => a['letter'].compareTo(b['letter']));

          return Material(
            child: Container(
              child: Stack(
                children: <Widget>[
                  AppsList(
                    apps: _apps,
                    scrollController: _controller,
                    letters: _letters,
                  ),
                  Positioned(
                    bottom: 0.0,
                    width: MediaQuery.of(context).size.width,
                    child: AppsAlphabeticScroll(
                      apps: _apps,
                      scrollController: _controller,
                      letters: _letters,
                    ),
                  )
                ],
            )),
          );
        }
      },
    );
  }
}

class AppsList extends StatelessWidget {
  AppsList({this.apps, this.scrollController, this.letters});

  final List<Application> apps;
  final List<Map> letters;
  final ItemScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      padding: EdgeInsets.only(bottom: scrollHeight + 10.0),
      itemScrollController: scrollController,
      itemCount: letters.length,
      itemBuilder: (BuildContext context, int index) {
        String letter = letters[index]['letter'];
        List<Application> letterApps = new List();
        for (Application app in apps) {
          if (app.appName[0].toUpperCase() == letter) {
            letterApps.add(app);
          }
        }
        return Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: <Widget>[
              Container(
                height: 50.0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    letter,
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: new NeverScrollableScrollPhysics(),
                itemCount: letterApps.length,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 100.0,
                  mainAxisSpacing: 5.0,
                  crossAxisSpacing: 5.0,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (BuildContext context, int index) {
                  ApplicationWithIcon app =
                      letterApps[index] as ApplicationWithIcon;
                  return RaisedButton(
                    elevation: 0.0,
                    color: Colors.black.withOpacity(0.2),
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                            height: 40.0,
                            child: Align(
                              child: Image.memory(app.icon),
                            )),
                        Container(
                          child: Text(
                            app.appName,
                            overflow: TextOverflow.fade,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(fontSize: 13.0),
                          ),
                          margin: EdgeInsets.only(top: 5.0),
                        )
                      ],
                    ),
                    onPressed: () {
                      DeviceApps.openApp(app.packageName);
                    },
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }
}

//class AppsAlphabeticScroll extends StatelessWidget {
//  AppsAlphabeticScroll({this.apps, this.scrollController, letters: const []});
//
//  final List<Application> apps;
//  final ItemScrollController scrollController;
//  List<Map> letters = new List();
//
//  @override
//  Widget build(BuildContext context) {
//    if (letters.length == 0) {
//      letters = lettersFromApps(apps);
//    }
//    return Container(
//        height: 52.0,
//        decoration: new BoxDecoration(
//          color: Colors.black12.withOpacity(0.3),
//        ),
//        padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
//        child: ListView.builder(
//          itemCount: letters.length,
//          scrollDirection: Axis.horizontal,
//          itemBuilder: (BuildContext context, int index) {
//            return Container(
//              width: 50.0,
//              margin: EdgeInsets.all(1.0),
//              child: RaisedButton(
//                shape: CircleBorder(),
//                child: Text(
//                  letters[index]['letter'].toString(),
//                ),
//                onPressed: () {
//                  scrollController.scrollTo(
//                      index: index,
//                      curve: Curves.linear,
//                      duration: Duration(milliseconds: 500));
//                },
//              ),
//            );
//          },
//        ));
//  }
//}

class _AppsAlphabeticScrollState extends State<AppsAlphabeticScroll>{
  List<Map> _letters = new List();

  @override
  void initState() {
    super.initState();
    List<Map> letters = widget.letters;
    if (letters.length == 0) {
      letters = lettersFromApps(widget.apps);
    }
    setState(() {
      _letters = letters;
    });
  }
  @override
  Widget build(BuildContext context) {
    List<Widget> lettersWidgets = new List();
    String currentLetter = '';
    double currentLetterLeft = 0.0;

    for(int i = 0; i < _letters.length; i++){
      final Map letter = _letters[i];
      if(letter['active']){
        currentLetter = letter['letter'];
        currentLetterLeft = i * widget.letterWidth;
        currentLetterLeft -= (widget._horizontalScrollController.hasClients ? widget._horizontalScrollController.offset : 0.0);
        currentLetterLeft += widget.letterWidth / 2;
      }
      lettersWidgets.add(
          Container(
            width: widget.letterWidth,
            alignment: Alignment.center,
            child: Text(letter['letter'], style: TextStyle(
              color: (letter['active'] ? Colors.red : Colors.white),
              fontSize: (letter['active'] ? 25.0 : 14.0)
            ),),
          )
      );
    }


    return Stack(
      children: <Widget>[
        Container(
            key: widget._key,
            height: scrollHeight,
            decoration: new BoxDecoration(
              color: Colors.black12.withOpacity(0.3),
            ),
            padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              child: ListView(
                controller: widget._horizontalScrollController,
                physics: new NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                children: lettersWidgets,
              ),
              onHorizontalDragUpdate: (DragUpdateDetails update){
                _dragHandle(update);
              },
              onHorizontalDragEnd: (DragEndDetails end){
                List<Map> letters = _letters;
                int index = 0;
                for(int i = 0; i < letters.length; i++){
                  if(letters[i]['active']){
                    index = i;
                    letters[i]['active'] = false;
                    break;
                  }
                }

                widget.scrollController.scrollTo(
                    index: index,
                    curve: Curves.linear,
                    duration: Duration(milliseconds: 500));

                setState(() {
                  _letters = letters;
                });
              },
            )
        ),
        SizedOverflowBox(
          size: Size(
//              MediaQuery.of(context).size.width/* + (widget._horizontalScrollController.hasClients ? widget._horizontalScrollController.offset : 0.0)*/,
              currentLetterLeft + 50.0,
              50.0
          ),
          child: Opacity(
            opacity: currentLetter == '' ? 0.0 : 0.7,
            child: Container(
              color: Colors.red,
              width: 50.0,
              height: 50.0,
              alignment: Alignment.center,
              margin: EdgeInsets.only(
                  bottom: scrollHeight * 2,
                  left: currentLetterLeft
              ),
              child: Text(currentLetter,
                style: TextStyle(
                    fontSize: 20.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _dragHandle(info){
    final RenderBox renderBox = widget._key.currentContext.findRenderObject();
    final size = renderBox.size;
    double x = info.globalPosition.dx;

    double offset = widget._horizontalScrollController.offset;
    double move = info.delta.dx.abs();
    double acceleration = 6.0;

    if(x > (size.width - 80.0)){
      offset += move * acceleration;
    }else if(x < 80){
      offset -= move * acceleration;
    }

    if(offset <= widget._horizontalScrollController.position.maxScrollExtent && offset >= widget._horizontalScrollController.position.minScrollExtent) {
      widget._horizontalScrollController.jumpTo(offset);
    }else{
      if(offset > widget._horizontalScrollController.position.maxScrollExtent){
        offset = widget._horizontalScrollController.position.maxScrollExtent;
      }else{
        offset = widget._horizontalScrollController.position.minScrollExtent;
      }
    }

    List<Map> letters = _letters;
    double xWithOffset = x + offset;
    for(int i = 0; i < letters.length; i++){
      double start = i * widget.letterWidth;
      double end = (i + 1) * widget.letterWidth;
      if(xWithOffset >= start && xWithOffset <= end){
        letters[i]['active'] = true;
      }else{
        letters[i]['active'] = false;
      }
    }

    setState(() {
      _letters = letters;
    });
  }
}

class AppsAlphabeticScroll extends StatefulWidget {
  AppsAlphabeticScroll({this.apps, this.scrollController, this.letters: const []});

  final List<Application> apps;
  final ItemScrollController scrollController;
  final List<Map> letters;

  final GlobalKey _key = GlobalKey();
  final ScrollController _horizontalScrollController = new ScrollController(initialScrollOffset: 0.0);
  final double letterWidth = 25.0;

  @override
  createState() => _AppsAlphabeticScrollState();
}

List<Map> lettersFromApps(List<Application> apps) {
  List<Map> letters = new List();
  List<String> addedLetters = new List();
  int appIdx = 0;
  apps.forEach((app) {
    final firstLetter = app.appName[0].toUpperCase();
    if (!addedLetters.contains(firstLetter)) {
      addedLetters.add(firstLetter);
      letters.add({'letter': firstLetter, 'top': appIdx * (50.0 + 8), 'active': false});
    }
    appIdx++;
  });
  letters.sort((a, b) => a['letter'].compareTo(b['letter']));

  return letters;
}
