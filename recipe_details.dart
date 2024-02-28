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
  late VideoWidget _videoWidget;
  late UserDetailsWidget _userDetailsWidget;
  late TabViewWidget _tabViewWidget;

  int _servings = 1;

  @override
  void initState() {
    super.initState();
    _videoWidget = VideoWidget(recipeSnapshot: widget.recipeSnapshot);
    _userDetailsWidget = UserDetailsWidget(recipeSnapshot: widget.recipeSnapshot);
  }

  @override
  Widget build(BuildContext context) {
    _tabViewWidget = TabViewWidget(
      recipeSnapshot: widget.recipeSnapshot,
  servings: _servings,
  currentPageIndex: _currentPageIndex, // Pass the current index
  updateServings: _updateServings,
  updateCurrentPageIndex: _updateCurrentPageIndex,
    );

    return Scaffold(
      body: ListView(
        children: [
          _videoWidget,
          _userDetailsWidget,
          _tabViewWidget
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
  bool _isVideoLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  void _initializeVideo() async {
    String videoUrl = await getVideoUrl(widget.recipeSnapshot['video']);
    _videoPlayerController = VideoPlayerController.network(videoUrl);
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
    return _isVideoLoading
        ? Center(child: CircularProgressIndicator())
        : AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoPlayerController),
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
          );
  }
}

class UserDetailsWidget extends StatelessWidget {
  final DocumentSnapshot recipeSnapshot;

  const UserDetailsWidget({Key? key, required this.recipeSnapshot}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(recipeSnapshot['userid']).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color.fromARGB(255, 255, 255, 255)),
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

        return ListTile(
          leading: FutureBuilder(
            future: getImageUrl(profilePicture),
            builder: (context, urlSnapshot) {
              if (urlSnapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(const Color.fromARGB(255, 255, 255, 255)),
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
    );
  }

  Future<String> getImageUrl(String imageName) async {
    final ref = FirebaseStorage.instance.ref().child(imageName);
    final url = await ref.getDownloadURL();
    return url;
  }
}

class TabViewWidget extends StatelessWidget {
  final DocumentSnapshot recipeSnapshot;
  final int servings;
  final int currentPageIndex;
  final Function(int) updateServings;
  final Function(int) updateCurrentPageIndex;

  const TabViewWidget({
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
            valueColor: AlwaysStoppedAnimation<Color>(const Color.fromARGB(255, 255, 255, 255)),
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

        String currentStep = steps.isNotEmpty
            ? steps[currentPageIndex]['description']
            : '';

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
                valueColor: AlwaysStoppedAnimation<Color>(const Color.fromARGB(255, 255, 255, 255)),
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
                return ListTile(
                  title: Text(comment['comment']),
                  subtitle: Text(comment['username']),
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
                        // Implement logic to add comment to Firestore
                        // Example:
                        // FirebaseFirestore.instance
                        //     .collection('recipe')
                        //     .doc(recipeSnapshot.id)
                        //     .collection('comments')
                        //     .add({
                        //   'comment': _commentController.text,
                        //   'username': 'User', // You can replace 'User' with the actual username
                        // });
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
