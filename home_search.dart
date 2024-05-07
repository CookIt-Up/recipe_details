import 'dart:async';

import 'package:cookitup/recipe_details.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeSearch extends StatefulWidget {
  final String title;

  HomeSearch({Key? key, required this.title}) : super(key: key);

  @override
  _HomeSearchState createState() => _HomeSearchState();
}

class _HomeSearchState extends State<HomeSearch> {
  late StreamController<Set<String>> matchedDocumentIdsStreamController;
  late Set<String> matchedDocumentIds;

  @override
  void initState() {
    super.initState();
    matchedDocumentIds = {};
    matchedDocumentIdsStreamController = StreamController<Set<String>>();
    initSearchResult();
  }

  Future<void> initSearchResult() async {
    matchedDocumentIds.clear();
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("recipe")
          .where("title", isEqualTo: widget.title)
          .get();

      for (var doc in querySnapshot.docs) {
        matchedDocumentIds.add(doc.id);
      }

      // Emit the updated set of document IDs to the stream
      matchedDocumentIdsStreamController.add(matchedDocumentIds);
    } catch (error) {
      print("Error searching: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFFD1E7D2),
        body: SafeArea(
          child: StreamBuilder<Set<String>>(
            stream: matchedDocumentIdsStreamController.stream,
            builder: (context, AsyncSnapshot<Set<String>> snapshot) {
              if (snapshot.hasData) {
                return ListView.separated(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    String documentId = snapshot.data!.toList()[index];
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('recipe')
                          .doc(documentId)
                          .snapshots(),
                      builder: (context,
                          AsyncSnapshot<DocumentSnapshot> documentSnapshot) {
                        if (documentSnapshot.hasData &&
                            documentSnapshot.data!.exists) {
                          var data = documentSnapshot.data!.data()
                              as Map<String, dynamic>;
                          String thumbnailUrl = data['thumbnail'];

                          return SizedBox(
                            width: 200,
                            height: 250,
                            child: FutureBuilder(
                              future: getImageUrl(thumbnailUrl),
                              builder: (context, urlSnapshot) {
                                if (urlSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator(
                                    // Define the color of the CircularProgressIndicator
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        const Color.fromARGB(
                                            255, 255, 255, 255)),

                                    // Define the thickness of the CircularProgressIndicator
                                    strokeWidth: 2.0,
                                  );
                                } else if (urlSnapshot.hasError) {
                                  return Text('Error: ${urlSnapshot.error}');
                                } else {
                                  var url = urlSnapshot.data as String;
                                  return GestureDetector(
                                    onTap: () {
                                      DocumentSnapshot recipeSnapshot =
                                          documentSnapshot.data!;

                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                RecipeDetailsPage(
                                                    recipeSnapshot:
                                                        recipeSnapshot)),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: NetworkImage(url),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(data['userid'])
                                              .snapshots(),
                                          builder: (context,
                                              AsyncSnapshot<DocumentSnapshot>
                                                  userSnapshot) {
                                            if (userSnapshot.hasData &&
                                                userSnapshot.data!.exists) {
                                              var userData =
                                                  userSnapshot.data!.data()
                                                      as Map<String, dynamic>;
                                              String dp =
                                                  userData['profilepic'];
                                              return Row(
                                                children: [
                                                  FutureBuilder<String>(
                                                    future: getImageUrl(dp),
                                                    builder: (context,
                                                        avatarUrlSnapshot) {
                                                      if (avatarUrlSnapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return CircularProgressIndicator(
                                                          // Define the color of the CircularProgressIndicator
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                      Color>(
                                                                  const Color
                                                                      .fromARGB(
                                                                      255,
                                                                      255,
                                                                      255,
                                                                      255)),

                                                          // Define the thickness of the CircularProgressIndicator
                                                          strokeWidth: 2.0,
                                                        );
                                                      } else if (avatarUrlSnapshot
                                                          .hasError) {
                                                        return Text(
                                                            'Error: ${avatarUrlSnapshot.error}');
                                                      } else {
                                                        String avatarUrl =
                                                            avatarUrlSnapshot
                                                                .data!;
                                                        // Use the avatarUrl to display the avatar image
                                                        return CircleAvatar(
                                                          backgroundImage:
                                                              NetworkImage(
                                                                  avatarUrl),
                                                          radius: 20,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                  SizedBox(width: 10),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        data['title'],
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                      SizedBox(height: 5),
                                                      Text(
                                                        userData['name'],
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w200,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            } else {
                                              print(
                                                  "User Snapshot Error: ${userSnapshot.error}");
                                              return SizedBox(); // Placeholder when data is loading or not available
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        } else {
                          return SizedBox(); // Placeholder when data is loading or not available
                        }
                      },
                    );
                  },
                  separatorBuilder: (ctx, index) {
                    return SizedBox(
                      height: 20,
                    );
                  },
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(
                    // Define the color of the CircularProgressIndicator
                    valueColor: AlwaysStoppedAnimation<Color>(
                        const Color.fromARGB(255, 255, 255, 255)),

                    // Define the thickness of the CircularProgressIndicator
                    strokeWidth: 2.0,
                  ),
                  // Show a loading indicator while waiting for data
                );
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    matchedDocumentIdsStreamController.close();
    super.dispose();
  }

  Future<String> getImageUrl(String imageName) async {
    final ref = FirebaseStorage.instance.ref().child(imageName);
    final url = await ref.getDownloadURL();
    return url;
  }
}

// Video player page
class VideoPlayerPage extends StatelessWidget {
  final String videoUrl;

  VideoPlayerPage({required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9, // You can adjust the aspect ratio as needed
          child: Container(
            color: Colors.black, // Placeholder color before video loads
            child: VideoPlayerWidget(videoUrl: videoUrl),
          ),
        ),
      ),
    );
  }
}

// Video player widget
class VideoPlayerWidget extends StatelessWidget {
  final String videoUrl;

  VideoPlayerWidget({required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    // Implement your video player widget here
    // This could be a webview, a package like chewie, or any other video player implementation
    return Text('Video Player: $videoUrl');
  }
}
