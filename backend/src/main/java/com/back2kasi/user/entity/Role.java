package com.back2kasi.user.entity;

/**
 * Platform-level roles for access control.
 *
 * <p>Business ownership is NOT modelled here. Whether a user is a
 * "business owner" is determined by the relationship between a User and the
 * Business entities they own — not by this enum.</p>
 *
 * <ul>
 *   <li>{@link #USER}  — every registered person on the platform.</li>
 *   <li>{@link #ADMIN} — platform administrators (future management/support).</li>
 * </ul>
 */
public enum Role {
    USER,
    ADMIN
}
