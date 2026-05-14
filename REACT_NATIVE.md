# React Native Mobile App Plan

This document outlines the architecture and implementation strategy for the MLM Mobile Application using the Genelet-powered backend.

## 1. Technical Stack
* **Framework**: React Native (Expo)
* **Navigation**: React Navigation 6.x
* **Networking**: Axios with `withCredentials: true` (for cookie persistence)
* **State Management**: Zustand (lightweight auth and global state)
* **UI Components**: React Native Paper (Material Design)

## 2. API Integration
The app communicates with the backend using the structure:
`https://{domain}/cgi-bin/goto/{ROLE}/json/{COMPONENT}?action={ACTION}`

Authenticated JSON responses include a CSRF token at `relationships.csrf`. Store the latest token for each signed-in role and include it as a `csrf` form field on mutating POST requests such as buying, changing profile defaults, changing passwords, replying to tickets, and admin compensation runs.

### Authentication Flow
* **Login**: `POST /m/json/member`
  * Body: `login`, `passwd`
  * Strategy: Server returns a `Set-Cookie` header with the `cm` session token.
* **Logout**: `GET /m/json/logout`
  * Clears session and redirects to landing.

## 3. Screen Roadmap

### Public Flow (Role: p)
1. **Landing Page**: 
   * Endpoint: `GET /p/json/member?action=startnew`
   * Purpose: Display welcome message and introductory package data.
2. **Sign Up**:
   * Endpoint: `POST /p/json/signup?action=insert`
   * Fields: `sidlogin`, `login`, `passwd`, `email`, `firstname`, `lastname`, `packageid`.
3. **Sign In**:
   * Standard login form targeting the Member role issuer.

### Member Flow (Role: m)
1. **Category Browser**:
   * Endpoint: `GET /m/json/category?action=topics`
   * Displays list of product categories available for the member.
2. **Product Gallery**:
   * Endpoint: `GET /m/json/gallery?action=topics&categoryid={id}`
   * Fetches products specific to the selected category.
3. **Dashboard**:
   * Endpoint: `GET /m/json/member?action=dashboard`
   * Displays user profile and business statistics.
4. **Basket Checkout**:
   * Endpoint: `POST /m/json/sale?action=buy`
   * Requires the latest member CSRF token.

## 4. Implementation Steps
1. **Scaffold**: Initialize Expo project and install dependencies.
2. **Auth Provider**: Create a secure wrapper to handle session cookies and persistence using `expo-secure-store`.
3. **Navigation**: Setup `Switch` navigation between `AuthStack` (Public) and `AppStack` (Member).
4. **Data Fetching**: Implement custom hooks for `useCategories` and `useProducts`.
5. **Polishing**: Add pull-to-refresh and loading skeletons.
