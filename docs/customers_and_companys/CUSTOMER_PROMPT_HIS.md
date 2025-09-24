# PRE PROMPT
    - *important* You don't need to explain what you did. I don't want to know, it's a waste of time. Focus on editing the file to meet the task I gave you.
    - First read `docs/customers_and_companys/CUSTOMER_SUMARY.md` file for review your memory and brainstrom your self.
    - For better answer me please read your mememory inside file `docs/customers_and_companys/CUSTOMER_SUMARY.md`
    - To give me better answers, please write a summary or review or document of each response to a file named `docs/customers_and_companys/CUSTOMER_SUMARY.md`, so AI can remember and improve my prompts next time.
    - *important* I'm giving you the Document functionality, so try not to mess with the other features.
    - *important* after finish add command in terminal "say finish prompt"

Topic: Customer detail page in tab job card
Detail: /fix error In tab 'Job card'.When pressed job card in tab i got error
``` 

══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following assertion was thrown building EditCardPage(dirty, state: _EditCardPageState#1e8a4):
There should be exactly one item with [DropdownButton]'s value: มาก (High).
Either zero or 2 or more [DropdownMenuItem]s were detected with the same value
'package:flutter/src/material/dropdown.dart':
Failed assertion: line 1796 pos 10: 'items == null ||
             items.isEmpty ||
             (initialValue == null && value == null) ||
             items
                     .where((DropdownMenuItem<T> item) => item.value == (initialValue ?? value))
                     .length ==
                 1'

The relevant error-causing widget was:
  EditCardPage
  EditCardPage:file:///Users/kiki/Works/02-SELLSTORY/mobile-sellstory/lib/app/routes.dart:90:19

When the exception was thrown, this was the stack:
#2      new DropdownButtonFormField (package:flutter/src/material/dropdown.dart:1796:10)
#3      _EditCardPageState._buildCustomerInterestSection (package:sellstory/features/board/view/edit_card_page.dart:6605:9)
#4      _EditCardPageState.build (package:sellstory/features/board/view/edit_card_page.dart:1547:19)
#5      StatefulElement.build (package:flutter/src/widgets/framework.dart:5833:27)
#6      ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5723:15)
#7      StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#8      Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#9      BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#10     BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#11     BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#12     WidgetsBinding.drawFrame (package:flutter/src/widgets/binding.dart:1259:21)
#13     RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#14     SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#15     SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#16     SchedulerBinding._handleDrawFrame (package:flutter/src/scheduler/binding.dart:1200:5)
#17     _invoke (dart:ui/hooks.dart:330:13)
#18     PlatformDispatcher._drawFrame (dart:ui/platform_dispatcher.dart:444:5)
#19     _drawFrame (dart:ui/hooks.dart:302:31)
(elided 2 frames from class _AssertionError)

════════════════════════════════════════════════════════════════════════════════════════════════════

flutter: 🔍 Loading document: fan8Q0INnmXPI26bVeOq (EST-250916-0055)
flutter: ✅ Loaded document: EST-250916-0055 (QT)
flutter: 🔍 Loading document: EPVk6NpGXdv7Pbsco04g (EST-250918-0056)
flutter: ✅ Loaded document: EST-250918-0056 (QT)
flutter: ✅ Loaded 2 related documents
Another exception was thrown: There should be exactly one item with [DropdownButton]'s value: มาก (High). 
flutter: 🔄 Loading product images for 1 products
Another exception was thrown: There should be exactly one item with [DropdownButton]'s value: มาก (High). 
Another exception was thrown: There should be exactly one item with [DropdownButton]'s value: มาก (High). 
flutter: ✅ Product images loaded successfully
flutter: 🎯 Card quotationTemplateId: MwDjGmET9ECYTGveik98
flutter: 🔄 Loading users for workspace: xKnLu20t7n6A0IJxl4NN
flutter: ✅ Loaded 2 users for workspace
flutter: 🔄 Loading customers from Firestore...
flutter: ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: │ #0   LoggerService.methodEntry (package:sellstory/core/services/logger_service.dart:200:13)
flutter: │ #1   FirestoreRepository.getCustomers (package:sellstory/data/repositories/firestore_repository.dart:1198:15)
flutter: │ #2   BoardController.getCustomers (package:sellstory/features/board/controller/board_controller.dart:673:43)
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 13:15:12.098 (+0:00:36.327768)
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 🐛 ➡️ Entering: FirestoreRepository.getCustomers with params: {workspaceId: xKnLu20t7n6A0IJxl4NN}
flutter: └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: │ #0   LoggerService.methodExit (package:sellstory/core/services/logger_service.dart:206:13)
flutter: │ #1   FirestoreRepository.getCustomers (package:sellstory/data/repositories/firestore_repository.dart:1210:15)
flutter: │ #2   <asynchronous suspension>
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 13:15:12.157 (+0:00:36.386641)
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 🐛 ⬅️ Exiting: FirestoreRepository.getCustomers with result: {count: 2}
flutter: └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: ✅ Customers loaded: 2 customers
flutter: 🔄 Loading companies for customer: WNF9tUB8pFM6QKQw9Fj3
flutter: ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: │ #0   LoggerService.methodEntry (package:sellstory/core/services/logger_service.dart:200:13)
flutter: │ #1   FirestoreRepository.getCustomers (package:sellstory/data/repositories/firestore_repository.dart:1198:15)
flutter: │ #2   BoardController.getCustomers (package:sellstory/features/board/controller/board_controller.dart:673:43)
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 13:15:12.160 (+0:00:36.389833)
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 🐛 ➡️ Entering: FirestoreRepository.getCustomers with params: {workspaceId: xKnLu20t7n6A0IJxl4NN}
flutter: └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: │ #0   LoggerService.methodExit (package:sellstory/core/services/logger_service.dart:206:13)
flutter: │ #1   FirestoreRepository.getCustomers (package:sellstory/data/repositories/firestore_repository.dart:1210:15)
flutter: │ #2   <asynchronous suspension>
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 13:15:12.205 (+0:00:36.434767)
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 🐛 ⬅️ Exiting: FirestoreRepository.getCustomers with result: {count: 2}
flutter: └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: ✅ Companies loaded for customer: 1 companies
flutter: 🔄 Loading quotation templates for workspace: xKnLu20t7n6A0IJxl4NN
Another exception was thrown: There should be exactly one item with [DropdownButton]'s value: มาก (High). 
flutter: 🔄 Updating visible columns for template: MwDjGmET9ECYTGveik98
flutter: 📋 Template found with 6 total columns
flutter: 📋 Filtered to 6 visible columns:
flutter:   - รายการ (product_field) - order: 0
flutter:   - จำนวน (predefined) - order: 1
flutter:   - ราคา/หน่วย (product_field) - order: 2
flutter:   - ยอดรวม (predefined) - order: 3
flutter:   - BewLnwZa001 (user_input) - order: 4
flutter:   - Bew1150  (user_input) - order: 5
flutter: ✅ Loaded 3 quotation templates
flutter: 🎯 Selected template: MwDjGmET9ECYTGveik98
flutter: 📋 Template columns count: 6
flutter:   - รายการ (product_field) - visible: true
flutter:   - จำนวน (predefined) - visible: true
flutter:   - ราคา/หน่วย (product_field) - visible: true
flutter:   - ยอดรวม (predefined) - visible: true
flutter:   - BewLnwZa001 (user_input) - visible: true
flutter:   - Bew1150  (user_input) - visible: true
flutter: 🔄 Loading companies for customer: WNF9tUB8pFM6QKQw9Fj3
flutter: ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: │ #0   LoggerService.methodEntry (package:sellstory/core/services/logger_service.dart:200:13)
flutter: │ #1   FirestoreRepository.getCustomers (package:sellstory/data/repositories/firestore_repository.dart:1198:15)
flutter: │ #2   BoardController.getCustomers (package:sellstory/features/board/controller/board_controller.dart:673:43)
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 13:15:12.272 (+0:00:36.501780)
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 🐛 ➡️ Entering: FirestoreRepository.getCustomers with params: {workspaceId: xKnLu20t7n6A0IJxl4NN}
flutter: └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Another exception was thrown: There should be exactly one item with [DropdownButton]'s value: มาก (High). 
flutter: ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: │ #0   LoggerService.methodExit (package:sellstory/core/services/logger_service.dart:206:13)
flutter: │ #1   FirestoreRepository.getCustomers (package:sellstory/data/repositories/firestore_repository.dart:1210:15)
flutter: │ #2   <asynchronous suspension>
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 13:15:12.344 (+0:00:36.573500)
flutter: ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
flutter: │ 🐛 ⬅️ Exiting: FirestoreRepository.getCustomers with result: {count: 2}
flutter: └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
flutter: ✅ Companies loaded for customer: 1 companies
Another exception was thrown: There should be exactly one item with [DropdownButton]'s value: มาก (High). 
```


Topic: Customer detail page
Detail: /fix error In tab 'ประวัติ' (History)
```

══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following _TypeError was thrown building:
type 'int' is not a subtype of type 'Timestamp?' in type cast

When the exception was thrown, this was the stack:
#0      _CustomerDetailPageState._buildHistoryTab.<anonymous closure>.<anonymous closure> (package:sellstory/features/customers/view/customer_detail_page.dart:1746:55)
#1      new ListView.separated.<anonymous closure> (package:flutter/src/widgets/scroll_view.dart:1477:32)
#2      SliverChildBuilderDelegate.build (package:flutter/src/widgets/scroll_delegate.dart:552:22)
#3      SliverMultiBoxAdaptorElement._build (package:flutter/src/widgets/sliver.dart:969:28)
#4      SliverMultiBoxAdaptorElement.createChild.<anonymous closure> (package:flutter/src/widgets/sliver.dart:985:55)
#5      BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3046:19)
#6      SliverMultiBoxAdaptorElement.createChild (package:flutter/src/widgets/sliver.dart:975:12)
#7      RenderSliverMultiBoxAdaptor._createOrObtainChild.<anonymous closure> (package:flutter/src/rendering/sliver_multi_box_adaptor.dart:372:23)
#8      RenderObject.invokeLayoutCallback.<anonymous closure> (package:flutter/src/rendering/object.dart:2881:17)
#9      PipelineOwner._enableMutationsToDirtySubtrees (package:flutter/src/rendering/object.dart:1206:15)
#10     RenderObject.invokeLayoutCallback (package:flutter/src/rendering/object.dart:2880:14)
#11     RenderSliverMultiBoxAdaptor._createOrObtainChild (package:flutter/src/rendering/sliver_multi_box_adaptor.dart:360:5)
#12     RenderSliverMultiBoxAdaptor.addInitialChild (package:flutter/src/rendering/sliver_multi_box_adaptor.dart:460:5)
#13     RenderSliverList.performLayout (package:flutter/src/rendering/sliver_list.dart:79:12)
#14     RenderObject.layout (package:flutter/src/rendering/object.dart:2762:7)
#15     RenderSliverEdgeInsetsPadding.performLayout (package:flutter/src/rendering/sliver_padding.dart:133:12)
#16     RenderSliverPadding.performLayout (package:flutter/src/rendering/sliver_padding.dart:371:11)
#17     RenderObject.layout (package:flutter/src/rendering/object.dart:2762:7)
#18     RenderViewportBase.layoutChildSequence (package:flutter/src/rendering/viewport.dart:673:13)
#19     RenderViewport._attemptLayout (package:flutter/src/rendering/viewport.dart:1684:12)
#20     RenderViewport.performLayout (package:flutter/src/rendering/viewport.dart:1575:20)
#21     RenderObject.layout (package:flutter/src/rendering/object.dart:2762:7)
#22     RenderProxyBoxMixin.performLayout (package:flutter/src/rendering/proxy_box.dart:115:18)
#23     RenderObject.layout (package:flutter/src/rendering/object.dart:2762:7)
#24     RenderProxyBoxMixin.performLayout (package:flutter/src/rendering/proxy_box.dart:115:18)
#25     RenderObject.layout (package:flutter/src/rendering/object.dart:2762:7)
#26     RenderProxyBoxMixin.performLayout (package:flutter/src/rendering/proxy_box.dart:115:18)
#27     RenderObject.layout (package:flutter/src/rendering/object.dart:2762:7)
#28     RenderProxyBoxMixin.performLayout (package:flutter/src/rendering/proxy_box.dart:115:18)
#29     RenderObject.layout (package:flutter/src/rendering/object.dart:2762:7)
#30     RenderProxyBoxMixin.performLayout (package:flutter/src/rendering/proxy_box.dart:115:18)
#31     RenderObject.layout (package:flutter/src/rendering/object.dart:2762:7)
#32     RenderProxyBoxMixin.performLayout (package:flutter/src/rendering/proxy_box.dart:115:18)
#33     RenderObject.layout (package:flutter/src/rendering/object.dart:2762:7)
#34     RenderProxyBoxMixin.performLayout (package:flutter/src/rendering/proxy_box.dart:115:18)
#35     RenderObject._layoutWithoutResize (package:flutter/src/rendering/object.dart:2610:7)
#36     PipelineOwner.flushLayout (package:flutter/src/rendering/object.dart:1157:18)
#37     PipelineOwner.flushLayout (package:flutter/src/rendering/object.dart:1170:15)
#38     RendererBinding.drawFrame (package:flutter/src/rendering/binding.dart:629:23)
#39     WidgetsBinding.drawFrame (package:flutter/src/widgets/binding.dart:1261:13)
#40     RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#41     SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#42     SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#43     SchedulerBinding._handleDrawFrame (package:flutter/src/scheduler/binding.dart:1200:5)
#44     _invoke (dart:ui/hooks.dart:330:13)
#45     PlatformDispatcher._drawFrame (dart:ui/platform_dispatcher.dart:444:5)
#46     _drawFrame (dart:ui/hooks.dart:302:31)
════════════════════════════════════════════════════════════════════════════════════════════════════

Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
Another exception was thrown: type 'int' is not a subtype of type 'Timestamp?' in type cast
```


Topic: Customer detail page
Detail: /fix error In tab 'ประวัติ' (History)
```
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following _TypeError was thrown building StreamBuilder<QuerySnapshot<Object?>>(dirty, state:
_StreamBuilderBaseState<QuerySnapshot<Object?>, AsyncSnapshot<QuerySnapshot<Object?>>>#1aed9):
type 'int' is not a subtype of type 'Timestamp?' in type cast

The relevant error-causing widget was:
  StreamBuilder<QuerySnapshot<Object?>>
  StreamBuilder:file:///Users/kiki/Works/02-SELLSTORY/mobile-sellstory/lib/features/customers/view/customer_detail_page.dart:1654:14

When the exception was thrown, this was the stack:
#0      _CustomerDetailPageState._buildHistoryTab.<anonymous closure>.<anonymous closure> (package:sellstory/features/customers/view/customer_detail_page.dart:1683:51)
#1      Sort._insertionSort (dart:_internal/sort.dart:77:36)
#2      Sort._doSort (dart:_internal/sort.dart:62:7)
#3      Sort.sort (dart:_internal/sort.dart:33:5)
#4      ListBase.sort (dart:collection/list.dart:321:10)
#5      _CustomerDetailPageState._buildHistoryTab.<anonymous closure> (package:sellstory/features/customers/view/customer_detail_page.dart:1680:22)
#6      StreamBuilder.build (package:flutter/src/widgets/async.dart:458:14)
#7      _StreamBuilderBaseState.build (package:flutter/src/widgets/async.dart:123:48)
#8      StatefulElement.build (package:flutter/src/widgets/framework.dart:5833:27)
#9      ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5723:15)
#10     StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#11     Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#12     BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#13     BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#14     BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#15     WidgetsBinding.drawFrame (package:flutter/src/widgets/binding.dart:1259:21)
#16     RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#17     SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#18     SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#19     SchedulerBinding._handleDrawFrame (package:flutter/src/scheduler/binding.dart:1200:5)
#20     _invoke (dart:ui/hooks.dart:330:13)
#21     PlatformDispatcher._drawFrame (dart:ui/platform_dispatcher.dart:444:5)
#22     _drawFrame (dart:ui/hooks.dart:302:31)

════════════════════════════════════════════════════════════════════════════════════════════════════

```

##
Topic: Customer detail page
Detail: In tab 'ประวัติ' (History) should show activity list like attach image.
Data from path: /workspaces/{workspaces id}/activities/. Use data where workspaceId is same as current workspace id.
userId is id of user who do the activity. show only type card-create

Example json
```
        "workspaces/xKnLu20t7n6A0IJxl4NN/activities": {
          "06gdvC2yyeHnk6fybg0h": {
            "boardId": "uysAvnxpDG4EbdbI7r1Y",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "d3z7heLqwYXXC3u3O9uR7iO9ium2",
            "userDisplayName": "BewLnwZa",
            "userPhotoURL": null,
            "type": "card-create",
            "timestamp": 1756116275079,
            "details": {
              "cardId": "3jxu5Me8oI3sjhAkLek2",
              "cardTitle": "New Job",
              "laneId": "9V1OtWzxrwJpLLFZoJHp",
              "laneName": "Bewtest01"
            }
          },
          "6rjcLlTUVihVM27FHkEb": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-move",
            "timestamp": 1756092318372,
            "details": {
              "cardId": "FIFVO81Kg4EfzdCUpZwI",
              "cardTitle": "123456",
              "sourceLaneId": "qesjwQS3saV9h3wzyYMz",
              "sourceLaneName": "In Progress",
              "destinationLaneId": "nvx4rzpcNcJk8GIw4YsK",
              "destinationLaneName": "Done"
            }
          },
          "97gfxUDi7B05W1qPFE04": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-create",
            "timestamp": 1756140015939,
            "details": {
              "cardId": "6VAYUMDzobYF1cTzMOax",
              "cardTitle": "123456ดด",
              "laneId": "D8FI6YQaNYQLZavNCnyC",
              "laneName": "To Do"
            }
          },
          "9L7nn622F7J7aikV8kyx": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-create",
            "timestamp": 1756929979477,
            "details": {
              "cardId": "MWt8RXcVWjHthMKJWe7T",
              "cardTitle": "Job Card Title",
              "laneId": "D8FI6YQaNYQLZavNCnyC",
              "laneName": "To Do"
            }
          },
          "9sZJglrOLqZQeDTpMJ8s": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-move",
            "timestamp": 1756052266623,
            "details": {
              "cardId": "G2OB4pCjtR0hSHAfmmeV",
              "cardTitle": "New Card",
              "sourceLaneId": "qesjwQS3saV9h3wzyYMz",
              "sourceLaneName": "In Progress",
              "destinationLaneId": "nvx4rzpcNcJk8GIw4YsK",
              "destinationLaneName": "Done"
            }
          },
          "AqLyZ1nsBCxMc8i3gxBo": {
            "boardId": "Mop2RUYjlM9kRoXGa001",
            "workspaceId": "xKnLu20t7n6A0IJxl4NN",
            "userId": "xvdZZF0XGsWwR1yZtUdG8cQQgtU2",
            "userDisplayName": "bew kiw",
            "userPhotoURL": null,
            "type": "card-move",
            "timestamp": 1756052223594,
            "details": {
              "cardId": "MSGxSxiHMSe1OCD34GeT",
              "cardTitle": "New Card",
              "sourceLaneId": "D8FI6YQaNYQLZavNCnyC",
              "sourceLaneName": "To Do",
              "destinationLaneId": "qesjwQS3saV9h3wzyYMz",
              "destinationLaneName": "In Progress"
            }
          },
        }

```



##
Topic: Customer detail page
Detail: In tab bar font is not same as in other page. Please change to same font.

```
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
```

##
Topic: Create card page and Edit card page Customer infomation section
Detail: In customer section, after pressed "+ New" in customer selection dropdown,

##
Topic: Customer page
Detail: After add customer, customer list not update. Please fix it.

##
Topic: Customer page
Detail: plz recheck data because i change workspace to Bew1150 should have customer list but after i change is still on 1111ffff is 0 customer.
Path data.json for understanding:firestore/backup-all-2025-09-20T17-32-26.json

````

flutter: 🔄 BoardController.render - Updating UI with new state:
flutter: - Lanes count: 3
flutter: - Lane: To Do (0 cards)
flutter: - Lane: In Progress (0 cards)
flutter: - Lane: Done (0 cards)
flutter: 🔍 Lane "To Do": 0/0 cards have hashtags
flutter: 🔍 Lane "In Progress": 0/0 cards have hashtags
flutter: 🔍 Lane "Done": 0/0 cards have hashtags
flutter: 🔍 Available assignees updated: 0 assignees
flutter: 🔍 UIDs: {}
flutter: 🔍 Display names: []
flutter: 🔍 Available customers updated: 0 customers
flutter: 🔍 Customers: {}
flutter: 🔍 \_updateAvailableHashtags() started
flutter: 🔍 Processing 3 lanes
flutter: 🔍 Lane: To Do has 0 cards
flutter: 🔍 Lane: In Progress has 0 cards
flutter: 🔍 Lane: Done has 0 cards
flutter: 🔍 Available hashtags updated: 0 hashtags from 0/0 cards
flutter: 🔍 Final hashtags list: {}
flutter: 🔍 availableHashtags after update: []
flutter: 🔍 \_updateAvailableInterests() started
flutter: 🔍 Processing 3 lanes
flutter: 🔍 Lane: To Do has 0 cards
flutter: 🔍 Lane: In Progress has 0 cards
flutter: 🔍 Lane: Done has 0 cards
flutter: 🔍 Available interests updated: 0 interests from 0/0 cards
flutter: 🔍 Interests: {}
flutter: 📱 Board state updated - 3 lanes
flutter: 🎯 Status Summary Cards Obx called - hasWorkspaces: true, lanes count: 3
flutter: 🎯 hasAnyFilter: false, selectedStatuses: []
flutter: 🎯 selectedInterests: []
flutter: 🔍 displayLanes getter called
flutter: 🔍 hasAnyFilter: false
flutter: 🔍 isSearching: false
flutter: 🔍 selectedInterests: []
flutter: 🔍 filteredLanes count: 3
flutter: 🔍 lanes count: 3
flutter: 🔍 Returning original lanes: 3 lanes
flutter: 🎯 Display lanes count: 3, All cards count: 0
flutter: 🔍 displayLanes getter called
flutter: 🔍 hasAnyFilter: false
flutter: 🔍 isSearching: false
flutter: 🔍 selectedInterests: []
flutter: 🔍 filteredLanes count: 3
flutter: 🔍 lanes count: 3
flutter: 🔍 Returning original lanes: 3 lanes
flutter: 🎯 StatusSummaryCards displayMode: LaneDisplayMode.totalBeforeDiscount for laneId: CdWn4l1fngZdgIRRGalF
flutter: 🎯 All laneDisplayModes: {}
flutter: 🎯 StatusSummaryCards build() called with 0 cards
flutter: 🎯 Selected statuses: []
flutter: 🎯 Display mode: LaneDisplayMode.totalBeforeDiscount
flutter: 🔍 displayLanes getter called
flutter: 🔍 hasAnyFilter: false
flutter: 🔍 isSearching: false
flutter: 🔍 selectedInterests: []
flutter: 🔍 filteredLanes count: 3
flutter: 🔍 lanes count: 3
flutter: 🔍 Returning original lanes: 3 lanes
flutter: 🔍 displayLanes getter called
flutter: 🔍 hasAnyFilter: false
flutter: 🔍 isSearching: false
flutter: 🔍 selectedInterests: []
flutter: 🔍 filteredLanes count: 3
flutter: 🔍 lanes count: 3
flutter: 🔍 Returning original lanes: 3 lanes
flutter: 🔍 Building board with 3 lanes
flutter: - Lane: To Do (0 cards)
flutter: - Lane: In Progress (0 cards)
flutter: - Lane: Done (0 cards)
flutter: 🔍 Building add card button for lane: To Do
flutter: 🔍 Add Card Button Debug for lane: To Do
flutter: - isOwner: true
flutter: - can(jobcard:create): true
flutter: - canCreate: true
flutter: - Current permissions: [*]
flutter: 🔍 Building add card button for lane: In Progress
flutter: 🔍 Add Card Button Debug for lane: In Progress
flutter: - isOwner: true
flutter: - can(jobcard:create): true
flutter: - canCreate: true
flutter: - Current permissions: [*]
flutter: 🔍 Building add card button for lane: Done
flutter: 🔍 Add Card Button Debug for lane: Done
flutter: - isOwner: true
flutter: - can(jobcard:create): true
flutter: - canCreate: true
flutter: - Current permissions: [*]
flutter: 🔍 DEBUG: availableHashtags current state:
flutter: 🔍 DEBUG: length = 0
flutter: 🔍 DEBUG: items = []
flutter: 🔍 DEBUG: availableHashtags current state:
flutter: 🔍 DEBUG: length = 0
flutter: 🔍 DEBUG: items = []

```

##
Topic: Customer Page
Detail: Clear and get new customer list is not working

##
Topic: Customer Page
Detail: After change workspace customer list not get from new workspace. It should clear old customer list and get new customer list from new workspace. can u print current board and customer count list.

##
Topic: Customer Page
Detail: customer list show in customer page is not have customer. When change workspace should clear customer list and get new customer list from new workspace. But now is not clear customer list when change workspace. So it show old customer list from old workspace.


##
Topic: Customer Page
Detail: /fix Customer list in addy"ajKydLWgXNQdBNJP3Efj" not have customer but is show 117 customer it should not show 0,I think app use customer from Bew1150 "3w5mum6fnev2IEKF7G9d"


##
Topic: Customer Page
Detail: Customer list not show. path customer "/workspaces/{workspaces}/customers" You can get data for example on "firestore/backup-workspaces-3w5mum6fnev2IEKF7G9d-2025-09-20T16-10-05.json" and "firestore/backup-workspaces-ajKydLWgXNQdBNJP3Efj-2025-09-20T16-06-32.json" those file is data in workspace.

##
Topic Customer Page
Detail: Customer list in customer page show list custom that is not in workspace.customer should show only in workspaces
Path: /workspaces/{workspaces}/customers

##
Topic: Customer lists
Detail: Check again plz, is still error. if i logout then login again customer list is back. But restart application by 'RUN AND DEBUG' customer list is gone

##
Topic: Customer lists
Detail: After restart application, Customer list is missing. But logout and login again is back. I attach image of case for understanding.


##
Topic:Function and section in customer dtail.
Detail: Add icon delete for delete customer. After pressed icon alert confirm dialog. pressed confirm go to delete customer from path "/workspaces/{workspace id}/customers/{customer id}".Can see structure from attach file .json

##
Topic:Function and section customer.
Detail: Add section address to customer deatil lib/features/customers/view/customer_detail_page.dart . Use data from firestore from
Path: /workspaces/{workspace id}/customers/{customer id}/customers.
Like attach image.

Example customer json
```

"HM4qDpnY8k6D7M7Sr37y": {
"hashtags": [
{
"color": "#8b5cf6",
"id": "hot",
"text": "hot"
},
{
"color": "#f43f5e",
"id": "sell",
"text": "sell"
},
{
"color": "#10b981",
"id": "pro",
"text": "pro"
},
{
"color": "#a855f7",
"id": "d3",
"text": "D3"
},
{
"color": "#10b981",
"id": "ddd",
"text": "DDD"
},
{
"color": "#6366f1",
"id": "edit",
"text": "edit"
}
],
"assignees": [
"2WPcgvluApNvAU0MyzQc0A6h7qu1"
],
"notes": [
{
"id": "note-1757928532705",
"text": "67890",
"timestamp": 1757928532705,
"type": "text",
"userDisplayName": "SEll OAT",
"userId": "ekgHtCF7fhNsH0mSpGxCPtdjkBJ2",
"userPhotoURL": null
},
{
"id": "note-1757908283125",
"text": "เทสว่า note สามารถรับข้อความยาวๆได้ไหมของลองดูหน่อยอยากรู้ว่ามันจะแสดงผลยังไง",
"timestamp": 1757908283126,
"type": "text",
"userDisplayName": "SEll OAT",
"userId": "ekgHtCF7fhNsH0mSpGxCPtdjkBJ2",
"userPhotoURL": null
},
{
"id": "note-1757908231058",
"text": "ๅ/-ภๅภ",
"timestamp": 1757908231058,
"type": "text",
"userDisplayName": "SEll OAT",
"userId": "ekgHtCF7fhNsH0mSpGxCPtdjkBJ2",
"userPhotoURL": null
},
{
"id": "note-1757907811211",
"text": "CDC",
"timestamp": 1757907811211,
"type": "text",
"userDisplayName": "SEll OAT",
"userId": "ekgHtCF7fhNsH0mSpGxCPtdjkBJ2",
"userPhotoURL": null
},
{
"id": "note-1757907800995",
"text": "Test",
"timestamp": 1757907800995,
"type": "text",
"userDisplayName": "SEll OAT",
"userId": "ekgHtCF7fhNsH0mSpGxCPtdjkBJ2",
"userPhotoURL": null
},
{
"fileName": "oatza",
"fileSize": null,
"id": "note-1757408684334",
"storagePath": null,
"text": "oatza",
"thumbnailStoragePath": null,
"thumbnailUrl": null,
"timestamp": 1757408684334,
"title": "oatza",
"type": "text",
"url": null,
"userDisplayName": null,
"userId": "ekgHtCF7fhNsH0mSpGxCPtdjkBJ2",
"userPhotoURL": null
}
]
},

```

```
