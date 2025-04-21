# Mini Task Hub

A modern task management application built with Flutter and Supabase, designed to help you organize your tasks efficiently.

## Features

### Authentication
- Secure login and signup with email/password
- Persistent session management
- Profile management

### Task Management
- Create, edit, and delete tasks
- Mark tasks as complete/incomplete
- Add task descriptions for detailed information
- Set due dates for your tasks
- Filter tasks (All, Active, Completed)
- Search tasks by title

### Multi-view Task Organization
- **Dashboard View**: Overview of all tasks with statistics
- **Calendar View**: Visualize tasks on a calendar by due date
- **Pending Tasks View**: Focus on incomplete tasks organized by due date

### Task Organization
- Tasks are grouped by date in the Pending Tasks view
- Calendar integration shows tasks on their respective due dates
- Visual indicators for overdue tasks

### User Interface
- Modern and clean design with a dark theme
- Responsive layout for different screen sizes
- Intuitive navigation with bottom navigation bar
- Pull-to-refresh functionality to update tasks
- Task statistics displayed on the dashboard

## Detailed Features

### Home Dashboard
The home dashboard offers a comprehensive view of your tasks with powerful organization tools:
- **Task Statistics**: Visual display of completed vs. pending tasks with completion rate
- **Search Functionality**: Quickly find tasks by typing in the search bar
- **Filter Tabs**: Toggle between All, Active, and Completed tasks with a single tap
- **Task List**: Each task shows title, creation date, and completion status
- **Swipe Actions**: Swipe left/right on tasks to delete or mark as complete
- **Quick Add**: Floating action button for adding new tasks

### Calendar View
The calendar view provides an intuitive way to visualize your tasks by date:
- **Monthly Calendar**: Navigate between months with intuitive controls
- **Date Selection**: Tap on any date to view tasks for that specific day
- **Task Indicators**: Dots under dates indicate the presence of tasks
- **Day View**: Below the calendar, see a detailed list of tasks for the selected day
- **Empty State Handling**: Friendly messages when no tasks exist for a date
- **Direct Task Management**: Add, edit, or delete tasks directly from calendar view
- **Date Highlighting**: Current day is highlighted for easy reference

### Pending Tasks List
The pending tasks screen helps you focus on what needs to be done:
- **Date Grouping**: Tasks are automatically grouped by due date
- **Chronological Order**: Tasks are sorted from earliest to latest due date
- **Overdue Indicators**: Visual warnings for tasks past their due date
- **No Due Date Section**: Special section for tasks without deadlines
- **Task Actions**: Complete or delete tasks directly from this view
- **Empty State**: Motivational message when all tasks are completed

### Task Management
The app provides a seamless experience for managing your tasks:
- **Task Creation**: 
  - Simple form with title, description, and due date fields
  - Optional due date selection with calendar picker
  - Form validation to ensure quality task data

- **Task Editing**:
  - Edit any task field including title, description, and due date
  - Option to clear due dates from existing tasks
  - Immediate visual feedback after updates

- **Task Deletion**:
  - Quick delete with swipe gestures
  - Confirmation to prevent accidental deletion
  - Success confirmation after deletion

- **Task Completion**:
  - Toggle completion status with a single tap
  - Visual indicators for completed tasks
  - Tasks remain in the database but can be filtered from view

## Demo Credentials

You can use the following credentials to log in:

- **Email**: 1@test.com
- **Password**: 12345678

## Screenshots

(Screenshots to be added)

## Getting Started

### Prerequisites
- Flutter 3.0.0 or higher
- Dart 2.17.0 or higher

### Installation

1. Clone the repository
```bash
git clone https://github.com/your-username/mini-task-hub.git
```

2. Navigate to the project directory
```bash
cd mini-task-hub
```

3. Get dependencies
```bash
flutter pub get
```

4. Run the app
```bash
flutter run
```

## Architecture

The application follows the GetX pattern for state management, providing:
- Reactive state management
- Dependency injection
- Route management

### Key Components
- **TaskService**: Handles all task-related operations with Supabase
- **AuthService**: Manages authentication state and user sessions
- **Screens**: Dashboard, Calendar, and Pending Tasks views
- **TaskModel**: Data model for the tasks

## Backend

The app uses Supabase as the backend service, providing:
- Real-time database
- Authentication services
- User management
- Data persistence

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Flutter](https://flutter.dev)
- [GetX](https://pub.dev/packages/get)
- [Supabase](https://supabase.io)
- [Table Calendar](https://pub.dev/packages/table_calendar)
