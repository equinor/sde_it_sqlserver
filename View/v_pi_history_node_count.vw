DROP VIEW V_PI_HISTORY_NODE_COUNT;

/* Formatted on 28.05.2015 06:41:23 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_PI_HISTORY_NODE_COUNT
(
   LOGDATE,
   DISTINCT_WIN_SERVER_CONNECTS,
   DISTINCT_CLIENT_CONNECTS,
   SUM_DISTINCT_NODES,
   SUM_TOTAL_CONNECTS
)
AS
     SELECT logdate,
            MAX (DECODE (node, 'Server', distinct_node_connects))
               distinct_server_connects,
            MAX (DECODE (node, 'Client', distinct_node_connects))
               distinct_client_connects,
              NVL (MAX (DECODE (node, 'Server', distinct_node_connects)), 0)
            + NVL (MAX (DECODE (node, 'Client', distinct_node_connects)), 0)
               sum_distinct_nodes,
            SUM (total_connects) sum_total_connects
       FROM (SELECT logdate,
                    node,
                    distinct_node_connects,
                    total_connects
               FROM (  SELECT TO_CHAR (START_TIME, 'YYYY-MM-DD') LOGDATE,
                              'Server' node,
                              COUNT (DISTINCT nodename) distinct_node_connects,
                              COUNT (*) total_connects
                         FROM process_information_history
                        WHERE REGEXP_LIKE (nodename,
                                           '^[[:alpha:]]+-(TW|W)[[:digit:]]',
                                           'i')
                     GROUP BY TO_CHAR (START_TIME, 'YYYY-MM-DD')
                     UNION ALL
                       SELECT TO_CHAR (START_TIME, 'YYYY-MM-DD') LOGDATE,
                              'Client' node,
                              COUNT (DISTINCT nodename) distinct_node_connects,
                              COUNT (*) total_connects
                         FROM process_information_history
                        WHERE NOT REGEXP_LIKE (nodename,
                                               '^[[:alpha:]]+-(TW|W)[[:digit:]]',
                                               'i')
                     GROUP BY TO_CHAR (START_TIME, 'YYYY-MM-DD')
                     ORDER BY 1 DESC))
   GROUP BY logdate
   ORDER BY logdate DESC;
