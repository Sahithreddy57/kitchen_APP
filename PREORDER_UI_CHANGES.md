# DRK Kitchen preorder UI update (dummy data)

This build uses local dummy menu data and dummy kitchen hours while the backend team prepares the combined Menu API.

## Behavior implemented
- Chicken Curry sizes 0.5 KG, 1 KG, 1.5 KG, and 2 KG are normal-order options.
- Chicken Curry sizes 5 KG (₹4,000) and 10 KG (₹7,800) are preorder-only options.
- Preorder status is stored on `DishOption`, so one product can have both normal and preorder-only sizes.
- If any cart line uses a preorder-only size, checkout automatically selects Pre-order and disables Order now.
- Preorder-only sizes can be scheduled today when the selected one-hour slot starts at least 2 hours from the current time and falls inside kitchen hours.

- If the cart has only normal sizes, both Order now and Pre-order remain available. Normal preorder uses the existing 45-minute lead time.
- Cart and checkout show the requested preorder notice.
- Dummy kitchen hours are 9:00 AM–9:00 PM every day.

## Switch to the real combined Menu API later
In `lib/core/api_config.dart`, set `kUseMockMenu` to `false` only after adapting `MenuApiService` to the backend's final combined response. Set `kUseMockHours` to `false` when the kitchen-hours API is ready. Make sure the combined Menu API returns each option's preorder flag (`pre_order_only: true/false`) and the kitchen start/end time fields required by the UI.
