# Monitor iOS App

A real-time monitoring application for iOS that displays posts from various sources with configurable relevance filtering.

## Features

### Notification Relevance Settings

The app includes a sophisticated relevance system that allows users to control which posts are important to them:

- **Configurable Threshold**: Users can set their relevance threshold (0-10) in the Settings tab
- **Consistent Experience**: The same relevance threshold is used for both push notifications and column display
- **Visual Indicators**: Posts in columns show their relevance score with color-coded badges
- **Real-time Updates**: When the threshold is changed, the "relevant" category updates immediately

#### Relevance Scoring

Posts are scored from 0-10 based on their importance:
- **0-3**: Low priority (gray badge)
- **4-6**: Medium priority (orange badge) 
- **7-8**: High priority (red badge)
- **9-10**: Critical priority (purple badge)

#### Column Categories

- **All**: Shows all posts regardless of relevance score
- **Relevant**: Shows only posts that meet or exceed your configured relevance threshold
- **Other categories**: Show posts filtered by topic (business, world, politics, technology, weather)

Posts that meet your relevance threshold are highlighted with a colored border in all column views.

#### Settings

Access the Settings tab to:
- Enable/disable push notifications
- Set your relevance threshold using the interactive slider
- Test notifications to verify your settings

The app remembers your preferences and applies them consistently across all features.

## Development

### Testing

The app includes comprehensive tests for the relevance functionality:

```bash
# Run tests using Xcode or xcodebuild
xcodebuild test -scheme monitor -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Architecture

- **NotificationManager**: Manages notification permissions and relevance threshold
- **PostsViewModel**: Handles post data and filtering for each category
- **ContentView**: Main app interface with responsive layout
- **PostsColumnView**: Individual column display with relevance indicators