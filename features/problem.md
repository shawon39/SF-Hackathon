# Hackathon Challenge: Dropillo Space & Asset Hub

## Company Overview

Dropillo Solutions is a fast-growing technology company known for its collaborative culture and innovative projects. Their modern office space in Dhaka is designed to support teamwork and productivity. The workspace includes a variety of meeting rooms:

* Soundproof focus pods (for individual work)
* Small huddle rooms (2–4 people) for quick sync-ups
* Medium collaboration rooms (6–8 people) for team meetings
* Large boardrooms (12–20 people) for presentations and client demos

In addition to rooms, the company has shared high-value equipment, like:

* Portable Video Conferencing Units (VCUs) – Type A and Type B
* VR/AR Testing Kits
* Portable Projectors
* Portable Monitors
* iPads
* iPhones
* Android Phones

---

## Current Problem

As Dropillo Solutions grew from 50 to over 250 employees in the last two years, its resource management system could not keep up. They currently rely on a mix of Outlook calendars, Teams messages, and informal shout-outs across the office to find and book rooms or equipment. This unstructured process has led to significant problems.

---

## Challenges Faced by the Team

* **Sarah (Project Manager):** Often finds the boardroom she booked for a client demo is already taken by someone else. Sometimes her booking is overwritten, and the VCU she needed is missing.
* **Rafiq (Senior Software Engineer):** Spends 20–30 minutes each day walking around the office looking for an available focus pod or huddle room. When he can’t find one, he works in a noisy environment, which affects his productivity.
* **Priya (R\&D Team):** Needs regular access to VR/AR kits for development. These are often missing or not returned by other teams, causing delays.
* **Hasan (Office Administrator):** Is overwhelmed by a flood of emails, Slack messages, and sticky notes from employees trying to book rooms or locate equipment. He has no central system to manage everything and spends hours trying to fix conflicts and track down items.

---

## Internal Asset Management System Backstory

Dropillo Solutions already has an internal Asset Management System to keep track of their growing inventory of high-value equipment and common rooms. This system, built and maintained by their infrastructure team, lives outside of Salesforce but acts as the single source of truth for detailed equipment and asset information. To power the Dropillo Space & Asset Hub, they expose a private API with all necessary info for rooms and equipment. Sample API response:

```json
{
  "rooms": [
    {
      "id": "R101",
      "name": "Focus Pod 1",
      "capacity": 1,
      "amenities": ["Noise-Canceling Headset"]
    },
    {
      "id": "R201",
      "name": "Huddle Room 1",
      "capacity": 4,
      "amenities": ["Whiteboard"]
    }
  ],
  "equipments": [
    {
      "id": "E001",
      "name": "Portable VCU Type A",
      "type": "PVCU",
      "serial_number": "VCUA-10234"
    },
    {
      "id": "E002",
      "name": "Portable Smartboard 1",
      "type": "Smartboard",
      "serial_number": "SB-45689"
    },
    {
      "id": "E011",
      "name": "iPad Pro 12.9 - 2024",
      "type": "Tablet",
      "serial_number": "IPD-43221"
    }
  ]
}
```

---

## Your Task: Build the "Dropillo Space & Asset Hub"

Create a Salesforce-based solution that solves these problems. Use:

* Custom Objects
* Apex Classes & Triggers
* Flows
* Lightning Web Components
* Reports & Dashboards

---

## Core Features

### For Employees

* View available rooms & equipment in real-time (show capacity & amenities).
* Book rooms or equipment for a selected time slot.
* Receive email notifications on booking status.
* Modify or cancel existing bookings.
* Filter/search by date, time, capacity, or equipment type.

### For Management

* View usage reports indicating high/low demand for rooms & equipment.
* Send a daily usage summary report automatically to top management.
* Dashboards showing:

  * Occupancy hours per room.
  * Number of bookings per equipment item.

---

## Technical Requirements

### 1. External API Integration

* Schedule a daily job (Apex Scheduler/Batch) to fetch rooms & equipment from the private API.

* Authenticate via OAuth 2.0 (Password grant) to obtain `access_token`:

  ```text
  grant_type: password
  client_id: 3MVG9fe4g9fhX0E5kgEO_FkTC4.S.o6gJin9.rPob_W9FRNAXNjui8wvwBSI.UKnJJk160mI5liMy0sEcZCTH
  client_secret: 63A1AF62D661AA1F18E68FA8D86B3C04B4620023FDB51A6BACF142083_B5F6B28
  username: sfhackathonbd@2025.com
  password: jP9kEs95ruw4Wm2@zOG4B7td7oJd7Ljw5AXAf5pG7
  ```

* Use `Authorization: Bearer YOUR_ACCESS_TOKEN` header when calling:

  ```http
  GET https://pumpshoeinc-dev-ed.my.salesforce.com/services/apexrest/resources
  ```

### 2. Activity Logging

* On every booking insert/update, fire an Apex Trigger to create a Task assigned to the booking user as a reminder.

### 3. User Interface

* Build Lightning Web Components for:

  * Real-time availability calendar/list view.
  * Booking form with date/time picker & amenity filters.
  * Management dashboard components (charts, tables).
* Follow Salesforce Lightning Design System for a consistent look & feel.

---

## Bonus (Optional)

* Auto-suggest alternative available time slots if preferred slot is booked.
* Automated email reminders for returning borrowed equipment.

---

## Hackathon Goal

Deliver a robust Salesforce solution that:

* Simplifies booking & reduces manual work.
* Prevents scheduling conflicts & asset confusion.
* Provides clear visibility for management.
* Enhances employee productivity & reduces stress.
* Demonstrates best practices in UI/UX & Salesforce development.
