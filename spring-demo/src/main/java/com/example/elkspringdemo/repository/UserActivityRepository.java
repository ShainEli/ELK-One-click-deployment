package com.example.elkspringdemo.repository;

import com.example.elkspringdemo.entity.UserActivity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface UserActivityRepository extends JpaRepository<UserActivity, Long> {

    List<UserActivity> findByUserId(String userId);

    List<UserActivity> findByActivityType(String activityType);

    List<UserActivity> findByUserIdAndActivityType(String userId, String activityType);

    @Query("SELECT ua FROM UserActivity ua WHERE ua.createdAt BETWEEN :startTime AND :endTime")
    List<UserActivity> findByCreatedAtBetween(@Param("startTime") LocalDateTime startTime,
                                            @Param("endTime") LocalDateTime endTime);

    @Query("SELECT ua FROM UserActivity ua WHERE ua.userId = :userId AND ua.createdAt >= :since")
    List<UserActivity> findRecentActivitiesByUser(@Param("userId") String userId,
                                                 @Param("since") LocalDateTime since);

    @Query("SELECT COUNT(ua) FROM UserActivity ua WHERE ua.activityType = :activityType")
    long countByActivityType(@Param("activityType") String activityType);
}
