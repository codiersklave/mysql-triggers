drop schema if exists `demo`;
create schema `demo` default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

use `demo`;

set names 'utf8mb4';
set foreign_key_checks = 0;

create table `person` (
    `id` int unsigned not null auto_increment,

    `first_name` varchar(80) default null,
    `middle_name` varchar(80) default null,
    `last_name` varchar(80) not null,

    `_version` int unsigned not null default 1,
    `_version_date` datetime not null default current_timestamp() on update current_timestamp(),
    `_version_user` int unsigned default null,

    `_deleted` datetime default null,
    `_deleted_user` int unsigned default null,

    primary key (`id`),
    foreign key (`_version_user`) references `user` (`id`),
    foreign key (`_deleted_user`) references `user` (`id`)
) engine=innodb;

create table `user` (
    `id` int unsigned not null auto_increment,

    `username` varchar(80) not null unique,

    `_version` int unsigned not null default 1,
    `_version_date` datetime not null default current_timestamp() on update current_timestamp(),
    `_version_user` int unsigned default null,

    `_deleted` datetime default null,
    `_deleted_user` int unsigned default null,

    primary key (`id`),
    foreign key (`_version_user`) references `user` (`id`),
    foreign key (`_deleted_user`) references `user` (`id`)
) engine=innodb;

create table `~person` (
    `id` int unsigned not null,

    `first_name` varchar(80) null,
    `middle_name` varchar(80) null,
    `last_name` varchar(80) not null,

    `_version` int unsigned not null,
    `_version_date` datetime not null,
    `_version_user` int unsigned null,

    `_deleted` datetime null,
    `_deleted_user` int unsigned null,

    primary key (`id`, `_version`),
    foreign key (`id`) references `person` (`id`) on delete cascade
) engine=innodb;

create table `~user` (
    `id` int unsigned not null,

    `username` varchar(80) not null,

    `_version` int unsigned not null,
    `_version_date` datetime not null,
    `_version_user` int unsigned null,

    `_deleted` datetime null,
    `_deleted_user` int unsigned null,

    primary key (`id`, `_version`),
    foreign key (`id`) references `user` (`id`) on delete cascade
) engine=innodb;

delimiter //

create trigger `person_before_update` before update on `person` for each row begin
    set new.`_version` = old.`_version` + 1;
end //
create trigger `person_after_update` after update on `person` for each row begin
    insert into `~person` (`id`, `first_name`, `middle_name`, `last_name`, `_version`, `_version_date`, `_version_user`,
                           `_deleted`, `_deleted_user`)
    values (old.`id`, old.`first_name`, old.`middle_name`, old.`last_name`, old.`_version`, old.`_version_date`,
            old.`_version_user`, old.`_deleted`, old.`_deleted_user`);
end //
create trigger `person_before_delete` before delete on `person` for each row begin
    if coalesce(@allow_delete, 0) <> 1 then
        signal sqlstate '45000' set message_text = 'Record deletion not allowed, set _deleted to current time instead';
    end if;
end //
create trigger `person_after_delete` after delete on `person` for each row begin
    set @allow_delete = 0;
end //

create trigger `user_before_update` before update on `user` for each row begin
    set new.`_version` = old.`_version` + 1;
end //
create trigger `user_after_update` after update on `user` for each row begin
    insert into `~user` (`id`, `username`, `_version`, `_version_date`, `_version_user`, `_deleted`, `_deleted_user`)
    values (old.`id`, old.`username`, old.`_version`, old.`_version_date`, old.`_version_user`, old.`_deleted`,
            old.`_deleted_user`);
end //
create trigger `user_before_delete` before delete on `user` for each row begin
    if coalesce(@allow_delete, 0) <> 1 then
        signal sqlstate '45000' set message_text = 'Record deletion not allowed, set deleted to current time instead';
    end if;
end //
create trigger `user_after_delete` after delete on `user` for each row begin
    set @allow_delete = 0;
end //

delimiter ;

set foreign_key_checks = 1;
