import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:firebase_auth/firebase_auth.dart';


class RecipeDetailsPage extends StatefulWidget {
  final DocumentSnapshot recipeSnapshot;

  const RecipeDetailsPage({Key? key, required this.recipeSnapshot})
      : super(key: key);

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  late VideoWidget _videoWidget;
  late UserDetailsWidget _userDetailsWidget;
  late TabViewWidget _tabViewWidget;

  int _servings = 1;

  @override
  void initState() {
    super.initState();
    _videoWidget = VideoWidget(recipeSnapshot: widget.recipeSnapshot);
    _userDetailsWidget =
        UserDetailsWidget(recipeSnapshot: widget.recipeSnapshot);
  }

@override
Widget build(BuildContext context) {
  _tabViewWidget = TabViewWidget(
    recipeSnapshot: widget.recipeSnapshot,
    servings: _servings,
    currentPageIndex: _currentPageIndex,
    updateServings: _updateServings,
    updateCurrentPageIndex: _updateCurrentPageIndex,
  );

  return Scaffold(
    backgroundColor: Color(0xFFD1E7D2),
    body: ListView(
      children: [
        _videoWidget,
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.recipeSnapshot['title'], // Display recipe title here
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.thumb_up),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.save),
                onPressed: () {},
              ),
            ],
          ),
        ),
        _userDetailsWidget,
        _tabViewWidget,
      ],
    ),
  );
}



  void _updateServings(int newServings) {
    setState(() {
      _servings = newServings;
    });
  }

  int _currentPageIndex = 0;

  void _updateCurrentPageIndex(int newIndex) {
    setState(() {
      _currentPageIndex = newIndex;
    });
  }
}

class VideoWidget extends StatefulWidget {
  final DocumentSnapshot recipeSnapshot;

  const VideoWidget({Key? key, required this.recipeSnapshot}) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  bool _isVideoLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  void _initializeVideo() async {
    try {
      String videoUrl = await getVideoUrl(widget.recipeSnapshot['video']);
      // ignore: deprecated_member_use
      _videoPlayerController = VideoPlayerController.network(videoUrl);
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: true,
        allowFullScreen: true, // Adjust according to your needs
        aspectRatio:4/3,
        // You can customize more options here
      );
      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.hasError) {
          print(
              "Video player error: ${_videoPlayerController.value.errorDescription}");
        }
      });

      setState(() {
        _isVideoLoading = false;
      });
    } catch (e) {
      print('error initializing video:$e');
    }
  }

  Future<String> getVideoUrl(String videoName) async {
    final ref = FirebaseStorage.instance.ref().child(videoName);
    final url = await ref.getDownloadURL();
    return url;
  }

  @override
Widget build(BuildContext context) {
  return _isVideoLoading
    ? AspectRatio(
        aspectRatio: 4 / 3, // Set a default aspect ratio while loading
        child: Center(child: CircularProgressIndicator()),
      )
    : AspectRatio(
        aspectRatio: _chewieController.aspectRatio ?? 16 / 9,
        child: Chewie(
          controller: _chewieController,
        ),
      );
}

}

class UserDetailsWidget extends StatelessWidget {
  final DocumentSnapshot recipeSnapshot;

  const UserDetailsWidget({Key? key, required this.recipeSnapshot})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(recipeSnapshot['userid'])
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFD1E7D2)),
            strokeWidth: 2.0,
          );
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

        return Row(
          children: [
            FutureBuilder(
              future: FirebaseStorageService.getImageUrl(profilePicture),
              builder: (context, urlSnapshot) {
                if (urlSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFFD1E7D2)),
                    strokeWidth: 2.0,
                  );
                } else if (urlSnapshot.hasError) {
                  return Text('Error: ${urlSnapshot.error}');
                } else {
                  var url = urlSnapshot.data as String;
                  return CircleAvatar(
                    backgroundImage: NetworkImage(url),
                  );
                }
              },
            ),
            SizedBox(width: 8),
            Expanded(
              child: Container(
                constraints: BoxConstraints(maxWidth: 250), // Adjust the max width as needed
                child: ListTile(
                  title: Text(
                    username,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.share),
                        onPressed: () {},
                      ),
                      
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class TabViewWidget extends StatelessWidget {
  final DocumentSnapshot recipeSnapshot;
  final int servings;
  final int currentPageIndex;
  final Function(int) updateServings;
  final Function(int) updateCurrentPageIndex;
  final TextEditingController _commentController = TextEditingController();
  

   TabViewWidget({
    Key? key,
    required this.recipeSnapshot,
    required this.servings,
    required this.currentPageIndex,
    required this.updateServings,
    required this.updateCurrentPageIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
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
                _buildIngredientsTab(servings),
                _buildStartCookTab(),
                _buildCommentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildIngredientsTab(servings) {
  final recipeSnapshot = this.recipeSnapshot;
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('recipe')
              .doc(recipeSnapshot.id)
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
            int totalIngredients = ingredients.length; // Count the ingredients
            return Text(
              'Ingredients- $totalIngredients',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            );
          },
        ),
        SizedBox(height: 20),
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
                    if (servings > 1) {
                      updateServings(servings - 1); // Decrease servings
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    updateServings(servings + 1);
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
              .doc(recipeSnapshot.id)
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
                String adjustedQuantity =
                    _calculateAdjustedQuantity(originalQuantity);
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
    double originalQuantityValue = double.tryParse(originalQuantity) ?? 0.0;
    double adjustedQuantityValue = originalQuantityValue * servings;
    return adjustedQuantityValue.toStringAsFixed(2);
  }

  Widget _buildStartCookTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipe')
          .doc(recipeSnapshot.id)
          .collection('steps')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFD1E7D2)),
            strokeWidth: 2.0,
          );
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No steps found');
        }

        List<QueryDocumentSnapshot> steps = snapshot.data!.docs;
        if (currentPageIndex >= steps.length) {
          updateCurrentPageIndex(steps.length - 1);
        }

        String currentStep =
            steps.isNotEmpty ? steps[currentPageIndex]['description'] : '';

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Step ${currentPageIndex + 1}:',
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
                      if (currentPageIndex > 0) {
                        updateCurrentPageIndex(currentPageIndex - 1);
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: () {
                      if (currentPageIndex < steps.length - 1) {
                        updateCurrentPageIndex(currentPageIndex + 1);
                      }
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
  return Column(
    children: [
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('recipe')
              .doc(recipeSnapshot.id)
              .collection('comments')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFFD1E7D2)),
                strokeWidth: 2.0,
              );
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No comments yet'));
            }

            List<QueryDocumentSnapshot> comments = snapshot.data!.docs;
            return ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                var comment = comments[index];
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(comment['userid'])
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFFD1E7D2)),
                        strokeWidth: 2.0,
                      );
                    }
                    if (userSnapshot.hasError) {
                      return Text('Error: ${userSnapshot.error}');
                    }
                    if (!userSnapshot.hasData ||
                        userSnapshot.data == null) {
                      return SizedBox(); // Placeholder for loading state
                    }

                    var userData = userSnapshot.data!;
                    String username = userData['name'] ?? 'Unknown User';
                    String profilePicture = userData['profilepic'] ?? '';

                    return ListTile(
                      leading:  FutureBuilder(
                        future: FirebaseStorageService.getImageUrl(profilePicture), // Use the FirebaseStorageService to get the image URL
                        builder: (context, urlSnapshot) {
                          if (urlSnapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFFD1E7D2)),
                              strokeWidth: 2.0,
                            );
                          } else if (urlSnapshot.hasError) {
                            return Text('Error: ${urlSnapshot.error}');
                          } else {
                            var url = urlSnapshot.data as String;
                            return CircleAvatar(
                              backgroundImage: NetworkImage(url),
                            );
                          }
                        },
                      ),
                      title: Text(comment['comment']),
                      subtitle: Text(username),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage('current_user_profile_url'),
                // You can replace 'current_user_profile_url' with the actual URL of the current user's profile picture
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: Colors.grey,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                              hintText: 'Write your comment...',
                              border: InputBorder.none,
                            ),
                            // You can use a TextEditingController to get the comment text
                            // controller: _commentController,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          /** 
                          FirebaseAuth auth = FirebaseAuth.instance;
                          User? user = auth.currentUser;

                          if (user != null) {
                            String userId = user.uid;
                            
                            // Now you can use userId when adding the comment to Firestore
                            FirebaseFirestore.instance
                              .collection('recipe')
                              .doc(recipeSnapshot.id)
                              .collection('comments')
                              .add({
                                'comment': _commentController.text,
                                'userid': userId,
                              });
                          } else {
                            // If user is not signed in, print a message
                            print('User needs to sign in to comment.');
                          }
                          */

                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  
}


class FirebaseStorageService {
  static Future<String> getImageUrl(String? imageName) async {
    if (imageName == null || imageName.isEmpty) {
      // Return a placeholder image URL or handle the case as needed
      return ''; // For example, return a default placeholder image URL
    }
    final ref = FirebaseStorage.instance.ref().child(imageName);
    try {
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      // Handle errors, such as image not found
      print('Error fetching image URL: $e');
      return ''; // Return a default placeholder image URL or handle the error case as needed
    }
  }
}