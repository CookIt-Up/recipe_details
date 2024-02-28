import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';


class RecipeDetailsPage extends StatefulWidget {
  final DocumentSnapshot recipeSnapshot;

  const RecipeDetailsPage({Key? key, required this.recipeSnapshot})
      : super(key: key);

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
  
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  int servings = 1;
  TextEditingController commentController = TextEditingController();
  int _currentPageIndex = 0;
   late PageController _pageController; 
  late VideoPlayerController _videoPlayerController;
  bool _isVideoLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // Initialize _pageController in initState
    _initializeVideo();
  }

  @override
  void dispose() {
    _pageController.dispose(); // Dispose _pageController in dispose method
     _videoPlayerController.dispose();
    super.dispose();
  }
  
void _initializeVideo() async {
  String videoUrl = await getVideoUrl(widget.recipeSnapshot['video']);
  _videoPlayerController = VideoPlayerController.network(
    videoUrl,
  );
  await _videoPlayerController.initialize();
  
  _videoPlayerController.addListener(() {
    if (_videoPlayerController.value.hasError) {
      print("Video player error: ${_videoPlayerController.value.errorDescription}");
    }
  });

  setState(() {
    _isVideoLoading = false;
  });
}




  Future<String> getVideoUrl(String videoName) async {
    final ref = FirebaseStorage.instance.ref().child(videoName);
    final url = await ref.getDownloadURL();
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
        _isVideoLoading
              ? const CircularProgressIndicator() // Show loading indicator while video is loading
              
                  : AspectRatio(
                    aspectRatio: 4 / 3, // Adjust aspect ratio as per your video's aspect ratio
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_videoPlayerController),
                        // Add playback controls
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_videoPlayerController.value.isPlaying) {
                                _videoPlayerController.pause();
                              } else {
                                _videoPlayerController.play();
                              }
                            });
                          },
                          child: Icon(
                            _videoPlayerController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                  ,

          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.recipeSnapshot['userid'])
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return Text('User not found');
              }

              var userData = snapshot.data!;
              String username = userData['name'] ?? 'Unknown User';
              String profilePicture = userData['profilepic'] ?? '';

              return ListTile(
              leading: FutureBuilder(
                future: getImageUrl(profilePicture),
                builder: (context, urlSnapshot) {
                  if (urlSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return CircularProgressIndicator(
                      // Define the color of the CircularProgressIndicator
                      valueColor:
                        AlwaysStoppedAnimation<Color>(const Color.fromARGB(255, 255, 255, 255)),

                      // Define the thickness of the CircularProgressIndicator
                      strokeWidth: 2.0,
                    );
                  } else if (urlSnapshot.hasError) {
                    return Text('Error: ${urlSnapshot.error}');
                  } else {
                    var url = urlSnapshot.data as String;
                    print('Url:$url');

                    return CircleAvatar(
                      backgroundImage: NetworkImage(url),
                    );
                  }
                },
              ),
              title: Row(
                children: [
                  Text(' $username'),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.save),
                    onPressed: () {},
                  ),
                ],
              ),
            );
          },
        ),

          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: 'Ingredients'),
                    Tab(text: 'Start Cook'),
                    Tab(text: 'Comments'),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      _buildIngredientsTab(),
                      _buildStartCookTab(),
                      _buildCommentsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
Future<String> getImageUrl(String imageName) async {
    final ref = FirebaseStorage.instance.ref().child(imageName);
    final url = await ref.getDownloadURL();
    return url;
  }
  

Widget _buildIngredientsTab() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quantity for $servings Serving',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (servings > 1) {
                        servings--;
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      servings++;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 20),
        // Display ingredients here based on servings
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('recipe')
              .doc(widget.recipeSnapshot.id)
              .collection('ingredients')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text('No ingredients found');
            }

            List<QueryDocumentSnapshot> ingredients = snapshot.data!.docs;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ingredients.map((ingredient) {
                String name = ingredient.id;
                String originalQuantity = ingredient['quantity'];
                String adjustedQuantity = _calculateAdjustedQuantity(originalQuantity);
                return Text('$name: $adjustedQuantity');
              }).toList(),
            );
          },
        ),
      ],
    ),
  );
}

String _calculateAdjustedQuantity(String originalQuantity) {
  // Convert originalQuantity to a numerical value
  double originalQuantityValue = double.tryParse(originalQuantity) ?? 0.0;
  // Calculate adjusted quantity based on servings
  double adjustedQuantityValue = originalQuantityValue * servings;
  // Return adjusted quantity as a string
  return adjustedQuantityValue.toStringAsFixed(2); // Adjust precision as needed
}


Widget _buildStartCookTab() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('recipe')
        .doc(widget.recipeSnapshot.id)
        .collection('steps')
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      }
      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Text('No steps found');
      }

      List<QueryDocumentSnapshot> steps = snapshot.data!.docs;
      // Ensure that _currentPageIndex doesn't exceed the bounds of steps array
      if (_currentPageIndex >= steps.length) {
        _currentPageIndex = steps.length - 1;
      }
      
      String currentStep = steps.isNotEmpty
          ? steps[_currentPageIndex]['description']
          : '';

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Step ${_currentPageIndex + 1}:',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              currentStep,
              style: TextStyle(fontSize: 18.0),
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      if (_currentPageIndex > 0) {
                        _currentPageIndex--;
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      if (_currentPageIndex < steps.length - 1) {
                        _currentPageIndex++;
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}


  Widget _buildCommentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(
                    'https://via.placeholder.com/50'), // Placeholder for current user's profile picture
              ),
              SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 45, // Adjust the height of the text field
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Write your comment here...',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          _submitComment();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitComment() {
    String comment = commentController.text.trim();
    if (comment.isNotEmpty) {
      // Add your Firestore logic here to add the comment
      // For example:
      // FirebaseFirestore.instance.collection('comments').add({
      //   'recipeId': widget.recipeSnapshot.id,
      //   'userId': loggedInUserId,
      //   'comment': comment,
      //   'timestamp': Timestamp.now(),
      // });
      // Clear the text field after submitting the comment
      commentController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Comment submitted!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please write a comment before submitting.')));
    }
  }
}