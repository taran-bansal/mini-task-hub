# DayTask - Personal Task Management App

A minimalist task management app built with Flutter and Supabase, featuring a clean and modern UI based on a Figma design.

## Features

- 🔐 Email/Password authentication
- ✨ Clean and modern UI
- 📝 Create and manage tasks
- ✅ Mark tasks as complete
- 🗑️ Delete tasks with swipe gesture
- 🎨 Custom theme and animations
- 📱 Responsive design

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Create a Supabase project at [supabase.com](https://supabase.com)

4. Create a new table named `tasks` with the following schema:
   ```sql
   create table public.tasks (
     id uuid default gen_random_uuid() primary key,
     created_at timestamp with time zone default timezone('utc'::text, now()) not null,
     title text not null,
     is_completed boolean default false,
     user_id uuid references auth.users not null
   );

   -- Enable RLS
   alter table public.tasks enable row level security;

   -- Create policies
   create policy "Users can create their own tasks" on public.tasks
     for insert with check (auth.uid() = user_id);

   create policy "Users can view their own tasks" on public.tasks
     for select using (auth.uid() = user_id);

   create policy "Users can update their own tasks" on public.tasks
     for update using (auth.uid() = user_id);

   create policy "Users can delete their own tasks" on public.tasks
     for delete using (auth.uid() = user_id);
   ```

5. Update `lib/main.dart` with your Supabase credentials:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

6. Run the app:
   ```bash
   flutter run
   ```

## Architecture

- **State Management**: GetX for reactive state management and navigation
- **Database**: Supabase for authentication and data storage
- **Theme**: Custom theme based on Figma design
- **Folder Structure**:
  ```
  lib/
  ├── app/
  │   └── theme.dart
  ├── auth/
  │   └── login_screen.dart
  ├── dashboard/
  │   ├── dashboard_screen.dart
  │   ├── task_tile.dart
  │   └── task_model.dart
  ├── services/
  │   └── supabase_service.dart
  └── main.dart
  ```

## Hot Reload vs Hot Restart

- **Hot Reload**: Updates UI and state while preserving app state
- **Hot Restart**: Completely restarts the app, losing all state

Use Hot Reload during development for quick UI changes, and Hot Restart when you need to reset the app state or when making significant changes to the app's initialization.

## Contributing

1. Fork the repository
2. Create a new branch
3. Make your changes
4. Submit a pull request

## License

MIT License
