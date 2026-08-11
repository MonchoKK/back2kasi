package com.back2kasi.business.repository;

import com.back2kasi.business.entity.Business;
import com.back2kasi.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * Data access layer for {@link Business} entities.
 *
 * <p>Extends {@link JpaRepository} which provides full CRUD and pagination
 * for free. The custom query methods below are expressed as method names —
 * Spring Data JPA translates them into SQL at startup.</p>
 *
 * <p>Method name → SQL translation examples:</p>
 * <ul>
 *   <li>{@code findByOwnerId(Long)} → {@code WHERE owner_id = ?}</li>
 *   <li>{@code existsByIdAndOwnerId(Long, Long)} → {@code SELECT EXISTS(WHERE id = ? AND owner_id = ?)}</li>
 * </ul>
 */
public interface BusinessRepository extends JpaRepository<Business, Long> {

    /**
     * Find all businesses owned by the given user.
     *
     * @param owner the owning {@link User} entity
     * @return list of businesses; empty list if the user owns none
     */
    List<Business> findByOwner(User owner);

    /**
     * Find all businesses owned by the given user ID.
     *
     * <p>Preferred over {@link #findByOwner(User)} in the service layer because
     * it avoids loading the full {@code User} entity just to perform a lookup.</p>
     *
     * @param ownerId the primary key of the owning user
     * @return list of businesses; empty list if none found
     */
    List<Business> findByOwnerId(Long ownerId);

    /**
     * Check whether a business with the given ID is owned by the given user.
     *
     * <p>Used by the service layer to authorise update and delete operations in a
     * single efficient query — rather than fetching the business and then checking
     * the owner manually.</p>
     *
     * <p>Translates to: {@code SELECT EXISTS(SELECT 1 FROM businesses WHERE id = ? AND owner_id = ?)}</p>
     *
     * @param id      the business primary key
     * @param ownerId the primary key of the expected owner
     * @return {@code true} if the business exists AND belongs to the given owner
     */
    boolean existsByIdAndOwnerId(Long id, Long ownerId);
}
