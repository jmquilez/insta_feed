import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:insta_feed/screens/home/items.dart';
import 'package:insta_feed/utils/colors.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _page = 0;
  late PageController pageController;

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void navigationTapped(int page) {
    pageController.jumpToPage(page);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        children: items,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: CupertinoTabBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.line_axis,
                  color: _page == 0 ? primaryColor : secondaryColor),
              label: 'Complete',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.waves,
                  color: _page == 1 ? primaryColor : secondaryColor),
              label: 'Non-render',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.airplane_ticket_outlined,
                  color: _page == 2 ? primaryColor : secondaryColor),
              label: 'Non-autoplay',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.train_outlined,
                  color: _page == 3 ? primaryColor : secondaryColor),
              label: 'Non-complete',
              backgroundColor: primaryColor,
            ),
            /*BottomNavigationBarItem(
              icon: Icon(Icons.sailing_rounded,
                  color: _page == 4 ? primaryColor : secondaryColor),
              label: 'Non-autoplay-rd',
              backgroundColor: primaryColor,
            ),*/
          ],
          onTap: navigationTapped,
        ),
      ),
    );
  }
}
