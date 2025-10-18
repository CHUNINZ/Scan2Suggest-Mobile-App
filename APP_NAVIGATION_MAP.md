# Complete App Navigation Map 🗺️

## Main Navigation Bar Structure

```
┌────────────────────────────────────────────────────────────┐
│                     APP TOP BAR                            │
│  [Icon]  Page Title                      [Actions/Badge]   │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│                                                            │
│                    PAGE CONTENT                            │
│                                                            │
│                                                            │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│              BOTTOM NAVIGATION BAR                         │
│                                                            │
│   Feed   Discover        [SCAN]       Notif   Profile     │
│    🔖      🔍             📱           🔔        👤         │
│   Tab 0   Tab 1         FAB          Tab 3    Tab 4       │
└────────────────────────────────────────────────────────────┘
```

---

## Complete Page Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        APP ENTRY POINT                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    ┌─────────────────┐
                    │  Splash Screen  │ (3 sec auto-login check)
                    └─────────────────┘
                              ↓
                    ┌─────────────────┐
                    │  Check Token?   │
                    └─────────────────┘
                    /                 \
            Token Found           No Token
                  ↓                     ↓
        ┌────────────────┐    ┌────────────────┐
        │   Social Feed  │    │   Onboarding   │
        │  (Main App)    │    │   → Sign In    │
        └────────────────┘    │   → Sign Up    │
                              │   → Verify     │
                              └────────────────┘
                                      ↓
                              ┌────────────────┐
                              │   Social Feed  │
                              │  (Main App)    │
                              └────────────────┘
```

---

## Main App Navigation (5 Tabs)

### **Tab 0: Social Feed** 🔖 (Default Landing Page)

```
┌──────────────────────────────────────────────────────────┐
│                     SOCIAL FEED                          │
│  Your personalized feed from people you follow          │
└──────────────────────────────────────────────────────────┘
│                                                          │
│  ┌────────────────────────────────────────────┐         │
│  │  [Avatar] Creator Name        2h ago       │         │
│  │                                             │         │
│  │  ┌────────────────────────────────────┐    │         │
│  │  │                                     │    │         │
│  │  │      Large Recipe Image            │    │         │
│  │  │                                     │    │         │
│  │  └────────────────────────────────────┘    │         │
│  │                                             │         │
│  │  Recipe Name                                │         │
│  │  Short description...                       │         │
│  │                                             │         │
│  │  ❤️ 45 likes   ⏱️ 30 min   [View Recipe] │         │
│  └────────────────────────────────────────────┘         │
│                                                          │
│  [More cards...]                                        │
│                                                          │
│  [Pull to Refresh] [Infinite Scroll]                   │
└──────────────────────────────────────────────────────────┘

Actions:
  - Tap Recipe Card → Recipe Details Page
  - Tap Creator Avatar/Name → User Profile Page
  - Pull Down → Refresh Feed
  - Scroll Down → Load More (Infinite Scroll)
```

---

### **Tab 1: Discover** 🔍

```
┌──────────────────────────────────────────────────────────┐
│                       DISCOVER                           │
│  Find new users to follow                               │
└──────────────────────────────────────────────────────────┘
│                                                          │
│  ┌────────────────────────────────────────────┐         │
│  │  ┌─────────┐                                │         │
│  │  │ Avatar  │  User Name                     │         │
│  │  │ Image   │  Short bio text...             │         │
│  │  └─────────┘                                │         │
│  │                                             │         │
│  │  📚 12 recipes  👥 345 followers  ➡️ 120   │         │
│  │                                             │         │
│  │                         [Follow / Following]│         │
│  └────────────────────────────────────────────┘         │
│                                                          │
│  [More user cards...]                                   │
│                                                          │
│  [Pull to Refresh]                                      │
└──────────────────────────────────────────────────────────┘

Actions:
  - Tap User Card → User Profile Page
  - Tap Follow Button → Follow/Unfollow (stays on page)
  - Pull Down → Refresh Suggestions
```

---

### **Tab 2 (Center): Scan Button** 📱 (Floating Action Button)

```
Tap Scan Button → Modal Pops Up ↓

┌──────────────────────────────────────────────────────────┐
│                  [Drag Handle]                           │
│                                                          │
│          Choose Scan Option                              │
│       Select what you want to scan                       │
│                                                          │
│  ┌────────────────┐        ┌────────────────┐          │
│  │                │        │                │          │
│  │   🍽️          │        │   🌿          │          │
│  │                │        │                │          │
│  │   Food         │        │   Ingredient   │          │
│  │ Scan prepared  │        │ Scan raw       │          │
│  │   dishes       │        │  ingredients   │          │
│  │                │        │                │          │
│  └────────────────┘        └────────────────┘          │
│                                                          │
│  [Tap Outside to Close]                                 │
└──────────────────────────────────────────────────────────┘

Actions:
  - Tap "Food" → Camera Scan (Food Mode)
      → Detect Food → Get AI Recipe → Recipe Page
  - Tap "Ingredient" → Camera Scan (Ingredient Mode)
      → Detect Ingredients → Ingredient Results Page
  - Tap Outside → Close Modal
```

---

### **Tab 3: Notifications** 🔔 (with Real-Time Badge)

```
┌──────────────────────────────────────────────────────────┐
│                   NOTIFICATIONS                          │
│  [Mark All as Read]                                      │
└──────────────────────────────────────────────────────────┘
│                                                          │
│  📚 All | ❤️ Likes | 👥 Follows | 💬 Comments          │
│                                                          │
│  ┌────────────────────────────────────────────┐         │
│  │ 👤 John liked your recipe "Chicken Adobo"  │  ←      │
│  │    2 hours ago                             │  Swipe  │
│  └────────────────────────────────────────────┘  Delete │
│                                                          │
│  ┌────────────────────────────────────────────┐         │
│  │ 👥 Sarah started following you             │         │
│  │    1 day ago                               │         │
│  └────────────────────────────────────────────┘         │
│                                                          │
│  [More notifications...]                                │
│                                                          │
│  [Pull to Refresh] [Infinite Scroll]                   │
└──────────────────────────────────────────────────────────┘

Badge Display:
  - Red circle with count (e.g., "3")
  - Shows on both navigation bar and app bar
  - Updates every 30 seconds
  - Only shows if count > 0
  - Shows "99+" if count > 99

Actions:
  - Tap Notification → Navigate to relevant page
  - Swipe Left → Delete notification
  - Tap "Mark All as Read" → Clear all
  - Filter by category (All, Likes, Follows, Comments)
  - Pull Down → Refresh
```

---

### **Tab 4: Profile** 👤

```
┌──────────────────────────────────────────────────────────┐
│                      PROFILE                             │
│                                              [Edit] [⚙️]  │
└──────────────────────────────────────────────────────────┘
│  ┌──────────────────────────────────────────────┐       │
│  │   ┌─────────┐                                │       │
│  │   │ Profile │  Your Name                     │       │
│  │   │  Image  │  @username                     │       │
│  │   └─────────┘  Your bio text...              │       │
│  │                                               │       │
│  │   📚 12 recipes  👥 345 followers  ➡️ 120   │  ← Tap│
│  └──────────────────────────────────────────────┘   to  │
│                                                     view │
│  ┌──────────────────────────────────────────────┐ lists │
│  │  My Recipes | Liked Recipes                  │       │
│  └──────────────────────────────────────────────┘       │
│                                                          │
│  [Recipe Grid Cards...]                                 │
│                                                          │
└──────────────────────────────────────────────────────────┘

Actions:
  - Tap "Edit" → Edit Profile Screen
      → Change profile picture
      → Update name, bio, location
  - Tap "Followers" → Followers List Page
  - Tap "Following" → Following List Page
  - Tap Recipe Card → Recipe Details Page
  - Switch Tabs: My Recipes / Liked Recipes
```

---

## Secondary Pages Navigation

### **Recipe Details Page** (From: Feed, Discover, Profile, Search)

```
┌──────────────────────────────────────────────────────────┐
│  [←]  Recipe Name                                        │
└──────────────────────────────────────────────────────────┘
│  ┌────────────────────────────────────────────┐         │
│  │                                             │         │
│  │        Large Recipe Image                  │         │
│  │                                             │         │
│  └────────────────────────────────────────────┘         │
│                                                          │
│  [Creator Avatar] Creator Name     [Follow/Following]   │
│                                                          │
│  ❤️ Like | 🔖 Bookmark | ⭐ Rate                       │
│                                                          │
│  📝 Description                                         │
│  ⏱️ 30 min | 🍽️ Main Course                          │
│                                                          │
│  🥕 Ingredients (4)                                     │
│    • Chicken - 1 kg                                     │
│    • Soy Sauce - 1/4 cup                               │
│    • Vinegar - 1/3 cup                                  │
│    • Garlic - 6 cloves                                  │
│                                                          │
│  📖 Instructions (5 steps)                              │
│    1. Marinate chicken...                               │
│    2. Heat oil in pan...                                │
│    3. ...                                               │
│                                                          │
└──────────────────────────────────────────────────────────┘

Actions:
  - Tap Creator → User Profile Page
  - Tap Like → Like/Unlike Recipe
  - Tap Bookmark → Bookmark/Unbookmark
  - Tap Rate → Show Rating Dialog (1-5 stars)
  - Tap Back → Return to previous page
```

---

### **User Profile Page** (From: Feed, Discover, Followers, Following)

```
┌──────────────────────────────────────────────────────────┐
│  [←]  User's Name                                        │
└──────────────────────────────────────────────────────────┘
│  ┌──────────────────────────────────────────────┐       │
│  │   ┌─────────┐                                │       │
│  │   │ Profile │  User's Name                   │       │
│  │   │  Image  │  @username                     │       │
│  │   └─────────┘  Their bio text...             │       │
│  │                                               │       │
│  │   📚 45 recipes  👥 1.2K followers  ➡️ 340  │  ← Tap│
│  │                                               │   to  │
│  │              [Follow / Following]             │  view │
│  └──────────────────────────────────────────────┘ lists │
│                                                          │
│  [Their Recipes Grid...]                                │
│                                                          │
└──────────────────────────────────────────────────────────┘

Actions:
  - Tap Follow → Follow/Unfollow User
  - Tap "Followers" → Followers List (this user's followers)
  - Tap "Following" → Following List (who this user follows)
  - Tap Recipe → Recipe Details Page
  - Tap Back → Return to previous page
```

---

### **Followers/Following List Page** (From: Profile, User Profile)

```
┌──────────────────────────────────────────────────────────┐
│  [←]  Followers / Following                              │
└──────────────────────────────────────────────────────────┘
│                                                          │
│  ┌────────────────────────────────────────────┐         │
│  │  [Avatar]  User Name           [Follow]    │         │
│  │            Short bio...                     │         │
│  └────────────────────────────────────────────┘         │
│                                                          │
│  ┌────────────────────────────────────────────┐         │
│  │  [Avatar]  Another User       [Following]  │         │
│  │            Their bio text...                │         │
│  └────────────────────────────────────────────┘         │
│                                                          │
│  [More users...]                                        │
│                                                          │
│  [Pull to Refresh]                                      │
└──────────────────────────────────────────────────────────┘

Actions:
  - Tap User Card → User Profile Page
  - Tap Follow Button → Follow/Unfollow
  - Pull Down → Refresh List
  - Tap Back → Return to previous page
```

---

### **Edit Profile Screen** (From: Profile)

```
┌──────────────────────────────────────────────────────────┐
│  [←]  Edit Profile                                       │
└──────────────────────────────────────────────────────────┘
│                                                          │
│              ┌─────────┐                                │
│              │ Current │  ← Tap to Change               │
│              │ Profile │                                 │
│              │  Image  │                                 │
│              └─────────┘                                 │
│                                                          │
│  ┌────────────────────────────────────────────┐         │
│  │ Name                                        │         │
│  │ [Your Name______________________]          │         │
│  └────────────────────────────────────────────┘         │
│                                                          │
│  ┌────────────────────────────────────────────┐         │
│  │ Bio                                         │         │
│  │ [Tell us about yourself________]            │         │
│  │ [______________________________]            │         │
│  └────────────────────────────────────────────┘         │
│                                                          │
│  ┌────────────────────────────────────────────┐         │
│  │ Location                                    │         │
│  │ [Your location_________________]            │         │
│  └────────────────────────────────────────────┘         │
│                                                          │
│              [Save Changes]                              │
│                                                          │
└──────────────────────────────────────────────────────────┘

Change Profile Picture Flow:
  Tap Avatar → Bottom Sheet Appears
    ┌────────────────────────────────┐
    │  📸 Take Photo                │
    │  🖼️  Choose from Gallery      │
    │  ❌ Remove Photo              │
    │  [Cancel]                     │
    └────────────────────────────────┘

Actions:
  - Tap Avatar → Show Image Picker Menu
  - Select Camera → Take photo → Preview → Auto-save
  - Select Gallery → Pick image → Preview → Auto-save
  - Edit Fields → Enable "Save Changes"
  - Tap Save → Upload & Update Profile
  - Tap Back → Confirm if unsaved changes
```

---

## Complete User Journey Examples

### Journey 1: New User Signs Up & Discovers Content

```
1. Splash Screen (3 sec)
2. Onboarding (swipe through)
3. Sign Up (enter email, password)
4. Verify Email (enter code)
5. → LANDS ON: Social Feed (empty state)
6. See message: "Start following users to see their recipes"
7. Tap "Discover" tab
8. See list of suggested users
9. Tap "Follow" on 3-4 interesting users
10. Return to "Feed" tab
11. Pull to refresh
12. ✅ See recipes from followed users!
```

---

### Journey 2: User Uploads Profile Picture

```
1. Open app (lands on Feed)
2. Tap "Profile" tab (rightmost)
3. See current profile with default avatar
4. Tap "Edit Profile" button
5. → NAVIGATE TO: Edit Profile Screen
6. Tap circular profile image
7. Bottom sheet appears with options
8. Tap "Choose from Gallery"
9. Select image from phone
10. See preview of selected image
11. Tap "Save Changes"
12. ✅ Profile picture uploads & updates
13. See success message
14. Return to Profile
15. ✅ New profile picture visible
```

---

### Journey 3: User Explores & Interacts with Recipes

```
1. Open app (lands on Feed)
2. Scroll through recipe cards
3. Tap on interesting recipe card
4. → NAVIGATE TO: Recipe Details Page
5. Read ingredients & instructions
6. Tap "Like" button (turns red)
7. Tap "Bookmark" button (turns green)
8. Tap "Rate" → Rate dialog appears
9. Select 5 stars → Submit
10. ✅ Recipe liked, bookmarked, and rated
11. Tap creator's name
12. → NAVIGATE TO: User Profile Page
13. See all their recipes
14. Tap "Follow" button
15. ✅ Now following this user
16. Tap "Followers" count
17. → NAVIGATE TO: Followers List
18. See list of their followers
19. Tap any follower
20. → NAVIGATE TO: Their Profile
21. [Continue exploring...]
```

---

### Journey 4: User Scans Food & Views Recipe

```
1. Open app (any tab)
2. Tap center "Scan" button (FAB)
3. Modal appears with options
4. Tap "Food" option
5. → NAVIGATE TO: Camera Scan Page
6. Point camera at food
7. Tap capture button
8. Image analyzing...
9. → NAVIGATE TO: AI Recipe Page
10. See AI-generated recipe with:
    - Ingredients list
    - Step-by-step instructions
    - Cooking time
    - Recipe type
11. Read and cook!
12. Tap back → return to previous tab
```

---

## Navigation Stack Summary

### Main Stack (Bottom Nav):
```
Feed (0) ←→ Discover (1) ←→ [Scan FAB] ←→ Notifications (3) ←→ Profile (4)
```

### Push Navigation (Modal/Page):
```
Any Page
  → Recipe Details
      → User Profile
          → Followers List
              → User Profile
                  → Recipe Details
                      → ...
```

### Special Modals:
```
Scan Button → Modal Overlay (not pushed to stack)
  → Food/Ingredient → Camera Page (pushed)
      → Results Page (replaced)
```

---

## Quick Reference: Where to Find Features

| Feature | Location | Tab | Additional Steps |
|---------|----------|-----|------------------|
| **Social Feed** | Main Nav | Tab 0 (Feed) | Default landing page |
| **Discover Users** | Main Nav | Tab 1 (Discover) | - |
| **Scan Food/Ingredient** | Main Nav | FAB (Scan) | Select Food or Ingredient |
| **Notifications** | Main Nav | Tab 3 | Badge shows unread count |
| **Your Profile** | Main Nav | Tab 4 | - |
| **Edit Profile** | Profile Tab | - | Tap "Edit Profile" button |
| **Upload Avatar** | Edit Profile | - | Tap profile picture |
| **Followers List** | Profile / User Profile | - | Tap "Followers" count |
| **Following List** | Profile / User Profile | - | Tap "Following" count |
| **Like Recipe** | Recipe Details | - | From any recipe card |
| **Bookmark Recipe** | Recipe Details | - | From recipe details |
| **Rate Recipe** | Recipe Details | - | Tap "Rate" button |
| **Follow User** | User Profile / Discover | - | Tap "Follow" button |
| **View User Profile** | Feed / Discover / Lists | - | Tap user name/avatar |
| **Search Recipes** | Any page | - | Use search icon in app bar |

---

**That's the complete navigation map! Every page is accessible and interconnected. 🎉**

