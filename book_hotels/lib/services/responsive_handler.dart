import 'package:flutter/material.dart';
import 'package:book_hotels/ui ux/smallmobile.dart';
import 'package:book_hotels/ui ux/largemobile.dart';
import 'package:book_hotels/ui ux/web.dart';


class Handler extends StatefulWidget {
  @override
  _HandlerState createState() => _HandlerState();
}

class _HandlerState extends State<Handler> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //theme: ThemeData.dark(),
      home: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Web();
          }
          if(constraints.maxHeight > 700 && constraints.maxHeight< 800){
            return Large();
          }
          else {
            return Small();
          }

        },
      ),
    );;
  }
}
