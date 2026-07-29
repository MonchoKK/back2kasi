package com.back2kasi.user.repository;

import com.back2kasi.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Spring Data JPA repository for {@link User} entities.
 *
 * <p>Extends {@link JpaRepository} to inherit full CRUD operations,
 * pagination, and sorting out of the box — no implementation needed.</p>
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * Find a user by their email address.
     *
     * <p>Used during authentication to look up a user by credential.</p>
     *
     * @param email the unique email address to search for
     * @return an {@link Optional} containing the user if found, or empty if not
     */
    Optional<User> findByEmail(String email);

    /**
     * Check whether a user with the given email already exists.
     *
     * <p>Used during registration to prevent duplicate accounts.</p>
     *
     * @param email the email address to check
     * @return {@code true} if a user with this email exists, {@code false} otherwise
     */
    boolean existsByEmail(String email);
}
