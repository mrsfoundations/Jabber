import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widget/chat_bar.dart';
import 'chats/chat_screen.dart';

class Contacts extends StatefulWidget {
  final from;

  Contacts(this.from);

  @override
  State<Contacts> createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  List userData = [];

  Future? getContactFunction;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getContactFunction = getContacts();
  }

  Future getContacts() async {
    if (await Permission.contacts.request().isGranted) {
      List<Contact> contact = await ContactsService.getContacts();
      List contactPhoneNumbers = [];
      for (var item in contact) {
        contactPhoneNumbers.add(item.phones!.first.value);
      }
      return contactPhoneNumbers;
    } else {
      throw "Please provide contact permission!";
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFromGroup = widget.from == "group";

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.black,
          ),
          onPressed: () {
            Get.back();
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Select contact",
          style: TextStyle(
            color: Colors.black,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(
                  context: context, delegate: MySearchDelegate(userData));
            },
            icon: const Icon(
              Icons.search,
              color: Colors.black,
            ),
          )
        ],
      ),
      body: FutureBuilder(
        future: getContactFunction,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Text("Loading..."),
            );
          } else if (snapshot.hasData) {
            return StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where('phoneNumber', whereIn: snapshot.data)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.data != null) {
                  userData = [];
                  List docs = snapshot.data.docs;
                  docs.forEach((item) {
                    userData.add(item);
                  });
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Text("Loading..."),
                  );
                } else {
                  return FutureBuilder(
                      future: getContacts(),
                      builder:
                          (BuildContext context, AsyncSnapshot<dynamic> snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Text("Loading..."),
                          );
                        } else {
                          return ChatListCardCaller(contactProfiles: userData);
                        }
                      });
                }
              },
            );
          } else {
            return Center(
              child:
                  Text(snapshot.error?.toString() ?? "Something Went Wrong!"),
            );
          }
        },
      ),
    );
  }
}

class ChatListCardCaller extends StatelessWidget {
  const ChatListCardCaller({
    Key? key,
    required this.contactProfiles,
  }) : super(key: key);

  final List contactProfiles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
          itemCount: contactProfiles.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: InkWell(
                onTap: () {
                  Get.to(
                      () => ChatScreen(
                            contactProfiles[index]['username'],
                            contactProfiles[index]['profileUrl'],
                            "${FirebaseAuth.instance.currentUser?.uid}__${contactProfiles[index]['uid']}",
                            isForSingleChatList: true,
                          ),
                      transition: Transition.fadeIn);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Hero(
                                  tag: contactProfiles[index]['username'],
                                  child: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: const Color(0xFFd6e2ea),
                                    backgroundImage: contactProfiles[index]
                                                ['profileUrl'] ==
                                            null
                                        ? null
                                        : NetworkImage(contactProfiles[index]
                                            ['profileUrl']),
                                    child: contactProfiles[index]
                                                ['profileUrl'] ==
                                            null
                                        ? const Icon(
                                            Icons.person_rounded,
                                            color: Colors.grey,
                                            size: 30,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contactProfiles[index]['username'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        "",
                                        maxLines: 1,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "",
                                      style: const TextStyle(
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Opacity(
                                      opacity: 0,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF006aff),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Text(""),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
    );
  }
}

class MySearchDelegate extends SearchDelegate {
  List resultContact;
  MySearchDelegate(this.resultContact);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(
            Icons.clear,
            color: Colors.black,
          ),
          onPressed: () {
            if (query.isEmpty) {
              close(context, null);
            } else {
              query = "";
            }
          },
        )
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.black,
        ),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
  Widget buildSuggestions(BuildContext context) {
    var listToShow;
    if (query.isNotEmpty) {
      listToShow = resultContact.where((e) {
        final title = e['username'].toLowerCase();
        final input = query.toLowerCase();
        return title.contains(input);
      }).toList();
    } else {
      listToShow = resultContact;
    }

    return ChatListCardCaller(contactProfiles: listToShow);
  }
}