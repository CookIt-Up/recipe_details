import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'profile.dart';
import 'grocery.dart';
import 'chatbot.dart';
import 'filter.dart';
import 'home_search.dart';
import 'recipe_details.dart';

class Home extends StatelessWidget {
  const Home({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
      routes: {
        '/userProfile': (context) => UserProfileScreen(),
        '/groceryList': (context) => GroceryListApp(),
        '/filter': (context) => FilterPage(),
        '/chatbot': (context) => ChatbotApp(),
      },
    );
  }
}

TextEditingController textFieldController = TextEditingController();
String searchTitle = '';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showHomeSearch = false;

  String recipe = "";
  List<DocumentSnapshot>? postDocumentsList;

  @override
  void initState() {
    super.initState();
    textFieldController.text = searchTitle;
  }

  void initSearching(String value) {
    String searchQuery = value.toLowerCase();
    FirebaseFirestore.instance
        .collection("recipe")
        .where("title", isGreaterThanOrEqualTo: searchQuery)
        .where("title",
            isLessThanOrEqualTo: searchQuery + '\uf8ff')
        .get()
        .then((querySnapshot) {
      List<DocumentSnapshot> filteredDocuments = [];
      Set<String> uniqueTitles = Set();

      querySnapshot.docs.forEach((doc) {
        var title = doc['title'];
        if (!uniqueTitles.contains(title)) {
          uniqueTitles.add(title);
          filteredDocuments.add(doc);
        }
      });

      setState(() {
        postDocumentsList = filteredDocuments;
      });
    }).catchError((error) {
      print("Error searching: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD1E7D2),
      appBar: AppBar(
        backgroundColor: Color(0xFFD1E7D2),
        titleSpacing: 0.0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserProfileScreen()),
                );
              },
              icon: Icon(
                Icons.account_circle,
                size: 30,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: textFieldController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search...',
                  ),
                  onChanged: (value) {
                    setState(() {
                      showHomeSearch = false;
                      recipe = value;
                    });
                    initSearching(value);
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Handle camera icon pressed
            },
            icon: Icon(Icons.camera_alt),
          ),
          IconButton(
            onPressed: () {
              // Handle voice icon pressed
            },
            icon: Icon(Icons.mic),
          ),
        ],
      ),
      body: showHomeSearch
          ? HomeSearch(title: searchTitle)
          : (recipe.isNotEmpty && postDocumentsList != null)
              ? ListView.builder(
                  itemCount: postDocumentsList!.length,
                  itemBuilder: (context, index) {
                    var document = postDocumentsList![index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          searchTitle = document['title'];
                          showHomeSearch = true;
                        });
                      },
                      child: ListTile(
                        title: Text(document['title']),
                      ),
                    );
                  },
                )
              : MainScreen(),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFFD1E7D2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                // Handle home icon pressed
              },
              icon: Icon(Icons.home),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/filter');
              },
              icon: Icon(Icons.soup_kitchen_sharp),
            ),
            IconButton(
              onPressed: () {
                // Handle icon 3 pressed
              },
              icon: Icon(Icons.add),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/groceryList');
              },
              icon: Icon(Icons.list_alt_outlined),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/chatbot');
              },
              icon: Icon(Icons.person_4_sharp),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  MainScreen({Key? key});

  final CollectionReference recipe =
      FirebaseFirestore.instance.collection('recipe');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color(0xFFD1E7D2),
      body: SafeArea(
        child: StreamBuilder(
          stream: recipe.orderBy('likes', descending: true).snapshots(),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              return GridView.builder(
                itemCount: snapshot.data.docs.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemBuilder: (context, index) {
                  var document = snapshot.data.docs[index];
                  var title = document['title'];
                  var thumbnailPath = document['thumbnail'];

                  return FutureBuilder(
                    future: getImageUrl(thumbnailPath),
                    builder: (context, urlSnapshot) {
                      if (urlSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color.fromARGB(255, 255, 255, 255),
                          ),
                          strokeWidth: 2.0,
                        );
                      } else if (urlSnapshot.hasError) {
                        return Text('Error: ${urlSnapshot.error}');
                      } else {
                        var url = urlSnapshot.data as String;
                        print('Url:$url');

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecipeDetailsPage(recipeSnapshot: document),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            } else {
              return Container();
            }
          },
        ),
      ),
    );
  }

  Future<String> getImageUrl(String imageName) async {
    final ref = FirebaseStorage.instance.ref().child(imageName);
    final url = await ref.getDownloadURL();
    return url;
  }
}
