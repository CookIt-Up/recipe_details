// import 'package:flutter/material.dart';

// class HomeIdel extends StatelessWidget {
//   const HomeIdel({Key? key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
    
//         Expanded(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: GridView.count(
//               shrinkWrap: true,
//               crossAxisCount: 2,
//               mainAxisSpacing: 20,
//               crossAxisSpacing: 20,
//               children: List.generate(20, (index) => MainScreen()),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class MainScreen extends StatelessWidget {
//   const MainScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         backgroundColor: Color(0xFFD1E7D2),
//         body: SafeArea(
//             child: Container(
//           decoration: BoxDecoration(
//               image: DecorationImage(
//                   image: AssetImage('assets/carrot_cake.jpg'),
//                   fit: BoxFit.cover,
                  
//                   ),
//                   borderRadius: BorderRadius.circular(10),
//                   ),
//         )),
//       ),
//     );
//   }
// }

// // Video player page
// class VideoPlayerPage extends StatelessWidget {
//   final String videoUrl = 'assets/carrot_cake.mp4';

//   VideoPlayerPage({videoUrl});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Video Player'),
//       ),
//       body: Center(
//         child: AspectRatio(
//           aspectRatio: 16 / 9, // You can adjust the aspect ratio as needed
//           child: Container(
//             color: Colors.black, // Placeholder color before video loads
//             child: VideoPlayerWidget(videoUrl: videoUrl),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Video player widget
// class VideoPlayerWidget extends StatelessWidget {
//   final String videoUrl = 'assets/carrot_cake.mp4';

//   VideoPlayerWidget({videoUrl});

//   @override
//   Widget build(BuildContext context) {
//     // Implement your video player widget here
//     // This could be a webview, a package like chewie, or any other video player implementation
//     return Text('Video Player: $videoUrl');
//   }
// }
