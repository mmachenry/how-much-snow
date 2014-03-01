create table prediction (
    created timestamp not null,
    predictedfor timestamp not null,
    latitude real not null,
    longitude real not null,
    metersofsnow real not null
);
