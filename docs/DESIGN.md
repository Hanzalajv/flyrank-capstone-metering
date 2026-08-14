# Usage Metering & Billing Engine — Design Document

## 1. Problem

This service answers three questions for a SaaS tenant:

1. How much has the tenant used?
2. How much does that usage cost?
3. Has the tenant reached its plan limits?

The system meters API calls and simulated AI-token usage, enforces monthly quotas, calculates usage cost, and synchronises subscription state with Stripe test mode.

---

## 2. Goals

The system must:

- Record billable usage.
- Prevent duplicate usage when a request is retried.
- Enforce monthly plan quotas before allowing billable actions.
- Return clear HTTP status codes when usage is rejected.
- Calculate usage costs using integer money units.
- Support Free and Pro plans.
- Support API-call and AI-token usage.
- Create Stripe Checkout sessions in test mode.
- Verify Stripe webhook signatures.
- Prevent duplicate Stripe webhook processing.
- Keep tenant data isolated.
- Provide a monthly usage and cost summary.

---

## 3. Non-goals

The core system will not implement:

- Real AI model calls.
- Real payments.
- Invoicing.
- Proration.
- Overage billing.
- Production payment processing.

Stripe will be used only in test mode.

---

## 4. Architecture

```text
                         ┌─────────────────┐
                         │ React Frontend  │
                         └────────┬────────┘
                                  │ HTTP
                                  ▼
                         ┌─────────────────┐
                         │ Express API     │
                         └────────┬────────┘
                                  │
             ┌────────────────────┼────────────────────┐
             │                    │                    │
             ▼                    ▼                    ▼
      ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
      │ MeterService │    │ CostService  │    │ StripeService│
      └──────┬───────┘    └──────────────┘    └──────┬───────┘
             │                                         │
             ▼                                         ▼
      ┌────────────────────────────────┐       ┌──────────────┐
      │ PostgreSQL                     │       │ Stripe Test  │
      │                                │◄──────│ Mode         │
      │ tenants                        │       └──────────────┘
      │ plans                          │
      │ subscriptions                  │
      │ usage_events                   │
      │ stripe_events                  │
      └────────────────────────────────┘