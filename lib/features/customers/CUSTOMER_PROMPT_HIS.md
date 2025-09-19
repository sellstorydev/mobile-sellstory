 # PRE PROMPT
    - *important* You don't need to explain what you did. I don't want to know, it's a waste of time. Focus on editing the file to meet the task I gave you.
    - First read `lib/features/board/BOARD_SUMMARY.md` file for review your memory and brainstrom your self. 
    - For better answer me please read your mememory inside file `lib/features/board/BOARD_SUMMARY.md`
    - To give me better answers, please write a summary or review or document of each response to a file named `lib/features/board/BOARD_SUMMARY.md`, so AI can remember and improve my prompts next time.
    - *important* I'm giving you the Document functionality, so try not to mess with the other features.

 
 
 
 
 
 
 
               SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarSliverDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppTheme.primaryOrange,
                      labelColor: AppTheme.primaryOrange,
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                      isScrollable: true,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(text: 'Job card (' '$_jobCardCount' ')'),
                        Tab(text: 'สิ่งที่ต้องทำ (' '$_todoCount' ')'),
                        const Tab(text: 'ประวัติ (0)'),
                        const Tab(text: 'คลังเอกสาร (0)'),
                        const Tab(text: 'โน๊ต (0)'),
                        const Tab(text: 'เอกสารการขาย (0)'),
                      ],
                    ),
                  ),
                ),