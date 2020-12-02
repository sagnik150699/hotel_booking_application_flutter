import 'package:flutter/material.dart';
import 'file:///C:/Users/DATA/Documents/Workspace/hotel_booking_application_flutter/book_hotels/lib/services/responsive_handler.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Handler();
  }
}




































//
// class MyApp extends StatelessWidget {
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       home: DesignLanding(),
//     );
//   }
// }
//
// class DesignLanding extends StatefulWidget {
//   @override
//   _DesignLandingState createState() => _DesignLandingState();
// }
//
// class _DesignLandingState extends State<DesignLanding> {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         theme: ThemeData.dark(),
//         home: Scaffold(
//           backgroundColor: Colors.black,
//           appBar: AppBar(
//             backgroundColor: Colors.black,
//             title: Text(
//               "Discover",
//               style: TextStyle(fontSize: 30.0),
//             ),
//             actions: <Widget>[
//               IconButton(
//                 icon: Icon(
//                   Icons.add_circle_outline,
//                   size: 40,
//                 ),
//                 onPressed: () {},
//               ),
//             ],
//           ),
//           body: SafeArea(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: <Widget>[
//                 Padding(
//                   //Search bar
//                   padding: const EdgeInsets.only(
//                       left: 20, top: 10, right: 20, bottom: 10),
//                   child: Card(
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(100)),
//                     child: ListTile(
//                       title: TextField(
//                         decoration: InputDecoration(
//                           contentPadding: EdgeInsets.all(8.0),
//                           icon: Icon(
//                             Icons.search,
//                           ),
//
//                           border: OutlineInputBorder(
//
//                             // borderRadius: BorderRadius.all(Radius.circular(20)),
//                               borderSide: BorderSide.none),
//                           //filled: true,
//                           hintText: " Search",
//                           hintStyle: TextStyle(
//                             fontSize: 20,
//                           ),
//                         ),
//                       ),
//                       trailing: Icon(Icons.pending),
//                     ),
//                   ),
//                 ),
//
//                 //Second widget
//                 SizedBox(
//                   height: 20,
//                   width: 400,
//                   child: Text("World Top 30"),
//                 ),
// // Third Widget
//                 Row(
//                   //First Data with image
//                   children: <Widget>[
//                     Expanded(
//                       // First Box
//                       child: Card(
//                         child: Column(
//                           children: <Widget>[
//                             ListTile(
//                               leading: CircleAvatar(
//                                   backgroundImage:
//                                   AssetImage('assets/sherlock.jpg'),
//                                   radius: 30.0),
//                               trailing: SizedBox(
//                                 height: 50,
//                                 width: 100,
//                                 child: Text(
//                                   "Sherlock Holmes",
//                                   style: TextStyle(fontSize: 20.0),
//                                 ),
//                               ),
//                             ),
//                             ListTile(
//                               leading: Text("Hello, I am a expert UI and UX designer",
//                                   style: TextStyle(fontSize: 15.0, color: Colors.grey)),
//                             ),
//                           ],
//                         ),
//                       ),
//                       flex: 1,
//                     ),
//                     Expanded(
//                       // Second Box
//                       child: Card(
//                         child: Column(
//                           children: <Widget>[
//                             ListTile( leading: CircleAvatar(
//                                 backgroundImage:
//                                 AssetImage('assets/sherlock.jpg'),
//                                 radius: 30.0),
//                               trailing: SizedBox(
//                                 height: 50,
//                                 width: 100,
//                                 child: Text(
//                                   "Sherlock Holmes",
//                                   style: TextStyle(fontSize: 20.0),
//                                 ),
//                               ),
//                             ),
//                             ListTile(
//                               leading: Text("Hello, I am a expert UI and UX designer",
//                                   style: TextStyle(fontSize: 15.0, color: Colors.grey)),
//                             ),
//                           ],
//                         ),
//                       ),
//                       flex: 1,
//                     ),
//                   ],
//                 ),
//                 SizedBox(
//                   height: 10,
//                   width: 400,
//
//                 ),
//                 // forth widget
//                 SizedBox(
//                   height: 20,
//                   width: 400,
//                   child: Text("Trending Categories",),
//                 ),
//
//
//                 // Fifth Widget
//                 Expanded(
//                   child: Column(
//                     children:<Widget> [
//                       Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           Chip(
//
//                             label: Text('UI DESIGN'),
//                             padding: EdgeInsets.symmetric(horizontal: 20.0),
//                             autofocus: true,
//                             // labelPadding: EdgeInsets.all(10.0),
//
//                           ),
//                           Chip(
//                             padding: EdgeInsets.symmetric(horizontal: 20.0),
//                             label: Text('UI DESIGN'),
//                           ),
//                           Chip(
//                             padding: EdgeInsets.symmetric(horizontal: 20.0),
//                             label: Text('UI DESIGN'),
//                           ),
//                         ],
//                       ),
//
//                       Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           Chip(
//                             padding: EdgeInsets.symmetric(horizontal: 20.0),
//                             label: Text('MARKETING'),
//
//                           ),
//                           Chip(
//                             padding: EdgeInsets.symmetric(horizontal: 20.0),
//                             label: Text('MANAGEMENT'),
//                             backgroundColor: Colors.deepOrangeAccent,
//                           ),
//                         ],
//                       ),
//
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           Chip(
//                             padding: EdgeInsets.symmetric(horizontal: 20.0),
//
//                             label: Text('UI DESIGN'),
//                             backgroundColor: Colors.deepOrangeAccent,
//                           ),
//                           Chip(
//                             padding: EdgeInsets.symmetric(horizontal: 20.0),
//
//                             label: Text('UI DESIGN'),
//                           ),
//                           Chip(
//                             padding: EdgeInsets.symmetric(horizontal: 20.0),
//
//                             label: Text('UI DESIGN'),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),flex: 6,
//                 ),
//                 SizedBox(
//                   height: 30,
//                   width: 400,
//                   child: Text("INDIA TOP 15",),
//                 ),
//                 Row(
//                   //Second Last row
//                   children: <Widget>[
//                     Expanded(
//                       // First Box
//                       child: Card(
//                         child: Column(
//                           children: <Widget>[
//                             ListTile(
//                               leading: CircleAvatar(
//                                   backgroundImage:
//                                   AssetImage('assets/sherlock.jpg'),
//                                   radius: 30.0),
//                               trailing: SizedBox(
//                                 height: 50,
//                                 width: 100,
//                                 child: Text(
//                                   "Sherlock Holmes",
//                                   style: TextStyle(fontSize: 20.0),
//                                 ),
//                               ),
//                             ),
//                             ListTile(
//                               leading: Text("Hello, I am a expert UI and UX designer",
//                                   style: TextStyle(fontSize: 15.0, color: Colors.grey)),
//                             ),
//                           ],
//                         ),
//                       ),
//                       flex: 1,
//                     ),
//                     Expanded(
//                       // Second Box
//                       child: Card(
//                         child: Column(
//                           children: <Widget>[
//                             ListTile( leading: CircleAvatar(
//                                 backgroundImage:
//                                 AssetImage('assets/sherlock.jpg'),
//                                 radius: 30.0),
//                               trailing: SizedBox(
//                                 height: 50,
//                                 width: 100,
//                                 child: Text(
//                                   "Sherlock Holmes",
//                                   style: TextStyle(fontSize: 20.0),
//                                 ),
//                               ),
//                             ),
//                             ListTile(
//                               leading: Text("Hello, I am a expert UI and UX designer",
//                                   style: TextStyle(fontSize: 15.0, color: Colors.grey)),
//                             ),
//                           ],
//                         ),
//                       ),
//                       flex: 1,
//                     ),
//                   ],
//                 ),
//
//                 Expanded(
//                   child: SizedBox(
//                     height: 10,
//                     width: 400,
//                     child: Text("Kolkata TOP 10",),
//                   ),
//                 ),
//                 Row(
//                   //Last Row
//                   children: <Widget>[
//                     Expanded(
//                       // First Box
//                       child: Card(
//                         child: Column(
//                           children: <Widget>[
//                             ListTile(
//                               leading: CircleAvatar(
//                                   backgroundImage:
//                                   AssetImage('assets/sherlock.jpg'),
//                                   radius: 30.0),
//                               trailing: SizedBox(
//                                 height: 50,
//                                 width: 100,
//                                 child: Text(
//                                   "Sherlock Holmes",
//                                   style: TextStyle(fontSize: 20.0),
//                                 ),
//                               ),
//                             ),
//                             ListTile(
//                               leading: Text("Hello, I am a expert UI and UX designer",
//                                   style: TextStyle(fontSize: 15.0, color: Colors.grey)),
//                             ),
//                           ],
//                         ),
//                       ),
//                       flex: 1,
//                     ),
//                     Expanded(
//                       // Second Box
//                       child: Card(
//                         child: Column(
//                           children: <Widget>[
//                             ListTile( leading: CircleAvatar(
//                                 backgroundImage:
//                                 AssetImage('assets/sherlock.jpg'),
//                                 radius: 30.0),
//                               trailing: SizedBox(
//                                 height: 50,
//                                 width: 100,
//                                 child: Text(
//                                   "Sherlock Holmes",
//                                   style: TextStyle(fontSize: 20.0),
//                                 ),
//                               ),
//                             ),
//                             ListTile(
//                               leading: Text("Hello, I am a expert UI and UX designer",
//                                   style: TextStyle(fontSize: 15.0, color: Colors.grey)),
//                             ),
//                           ],
//                         ),
//                       ),
//                       flex: 1,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ));
//   }
// }
