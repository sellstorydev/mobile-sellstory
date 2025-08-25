# Global Hashtag Input Field Component

A reusable Flutter component for selecting hashtags with search functionality and multi-select capability.

## Features

- 🔍 **Search Functionality**: Search through available hashtags
- ✅ **Multi-Select**: Choose multiple hashtags or single selection
- 🎨 **Color-Coded**: Each hashtag has its own color
- 📊 **Usage Tracking**: Shows how many times each hashtag has been used
- 🔧 **Configurable**: Multiple configuration options
- 🌐 **Global**: Can be used across multiple pages

## Components

### 1. HashtagInputField Widget

The main component for selecting hashtags.

#### Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `selectedHashtags` | `List<String>` | Yes | - | List of selected hashtag IDs |
| `availableHashtags` | `List<HashtagOption>` | Yes | - | List of available hashtag options |
| `onHashtagsChanged` | `Function(List<String>)` | Yes | - | Callback when hashtags change |
| `label` | `String` | No | 'แฮชแท็ก' | Field label |
| `hintText` | `String` | No | 'เลือกแฮชแท็ก' | Placeholder text |
| `isRequired` | `bool` | No | `false` | Whether field is required |
| `allowMultiple` | `bool` | No | `true` | Allow multiple selection |
| `showSearch` | `bool` | No | `true` | Show search functionality |
| `workspaceId` | `String?` | No | `null` | Workspace ID for data fetching |

### 2. HashtagOption Class

Data model for hashtag options.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique identifier |
| `name` | `String` | Display name |
| `color` | `String` | Hex color code |
| `totalUsage` | `int` | Total usage count |
| `enabled` | `bool` | Whether hashtag is enabled |
| `scopes` | `Map<String, bool>` | Available scopes (customer, product, etc.) |

## Usage

### Basic Implementation

```dart
import '../../../core/widgets/hashtag_input_field.dart';
import '../../../core/services/hashtag_service.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final HashtagService _hashtagService = HashtagService();
  List<HashtagOption> _availableHashtags = [];
  List<String> _selectedHashtags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHashtags();
  }

  Future<void> _loadHashtags() async {
    try {
      const workspaceId = 'your-workspace-id';
      final hashtags = await _hashtagService.getHashtagsByScope(workspaceId, 'customer');
      
      setState(() {
        _availableHashtags = hashtags;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading hashtags: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            HashtagInputField(
              selectedHashtags: _selectedHashtags,
              availableHashtags: _availableHashtags,
              onHashtagsChanged: (hashtags) {
                setState(() {
                  _selectedHashtags = hashtags;
                });
              },
              label: 'แฮชแท็ก',
              hintText: 'เลือกแฮชแท็ก',
            ),
        ],
      ),
    );
  }
}
```

### Single Selection

```dart
HashtagInputField(
  selectedHashtags: _selectedHashtags,
  availableHashtags: _availableHashtags,
  onHashtagsChanged: (hashtags) {
    setState(() {
      _selectedHashtags = hashtags;
    });
  },
  allowMultiple: false, // Single selection only
  label: 'แฮชแท็ก (เลือกได้ 1 อัน)',
  hintText: 'เลือกแฮชแท็ก 1 อัน',
),
```

### Required Field

```dart
HashtagInputField(
  selectedHashtags: _selectedHashtags,
  availableHashtags: _availableHashtags,
  onHashtagsChanged: (hashtags) {
    setState(() {
      _selectedHashtags = hashtags;
    });
  },
  isRequired: true,
  label: 'แฮชแท็ก (จำเป็น)',
  hintText: 'กรุณาเลือกแฮชแท็ก',
),
```

### Without Search

```dart
HashtagInputField(
  selectedHashtags: _selectedHashtags,
  availableHashtags: _availableHashtags,
  onHashtagsChanged: (hashtags) {
    setState(() {
      _selectedHashtags = hashtags;
    });
  },
  showSearch: false, // Hide search functionality
  label: 'แฮชแท็ก (ไม่มีค้นหา)',
  hintText: 'เลือกแฮชแท็ก',
),
```

## Data Conversion

### Converting to String for Storage

```dart
final hashtagString = _hashtagService.hashtagIdsToString(
  _selectedHashtags, 
  _availableHashtags
);
// Result: "#hot #urgent #followup"
```

### Converting from String to IDs

```dart
final hashtagIds = _hashtagService.stringToHashtagIds(
  hashtagString, 
  _availableHashtags
);
// Result: ["hot", "urgent", "followup"]
```

## Service Methods

### HashtagService

The service provides methods for managing hashtags:

- `getWorkspaceHashtags(workspaceId)` - Get all hashtags for a workspace
- `getHashtagsByScope(workspaceId, scope)` - Get hashtags filtered by scope
- `incrementHashtagUsage(workspaceId, hashtagId, scope)` - Update usage count
- `createHashtag(workspaceId, name, color, scopes)` - Create new hashtag
- `updateHashtag(workspaceId, hashtagId, {...})` - Update hashtag
- `deleteHashtag(workspaceId, hashtagId)` - Delete hashtag

## Database Structure

The component expects hashtag data in the following Firestore structure:

```json
{
  "workspaces": {
    "workspaceId": {
      "companyProfile": {
        "hashtagSettings": {
          "isEnabled": true,
          "mode": "manual",
          "masterList": [
            {
              "id": "hot",
              "name": "hot",
              "color": "#ef4444",
              "totalUsage": 15,
              "enabled": true,
              "scopes": {
                "customer": true,
                "product": true,
                "jobBoard": true,
                "company": true,
                "chat": true
              },
              "usage": {
                "customer": 8,
                "product": 3,
                "jobBoard": 4
              }
            }
          ]
        }
      }
    }
  }
}
```

## Demo

See `lib/features/customers/view/hashtag_demo_page.dart` for a complete demo of all features.

## Integration Examples

### Customer Page
The component is already integrated into the customer add/edit page. See `lib/features/customers/view/add_edit_customer_page.dart` for implementation details.

### Job Card Page
Can be integrated into job card creation/editing pages for tagging job cards.

### Product Page
Can be used for tagging products with relevant hashtags.

## Customization

The component uses the app's theme colors and can be customized by modifying the `HashtagInputField` widget or creating a custom theme.
