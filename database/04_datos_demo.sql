--
-- PostgreSQL database dump
--

\restrict ibw2I1NbZjZhZ7F71MyPjIkzP9wQcSbvmjJXhrODe83QhHnlUA24DdJKbjduTmZ

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

-- Started on 2026-10-24 03:54:14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5040 (class 0 OID 25675)
-- Dependencies: 222
-- Data for Name: cine; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cine (id_cine, nombre, direccion, ciudad, pais) FROM stdin;
1	IMAX San José	Centro Comercial de Prueba	San José	Costa Rica
\.


--
-- TOC entry 5042 (class 0 OID 25689)
-- Dependencies: 224
-- Data for Name: sala; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sala (id_sala, nombre, tipo_proyeccion, estado, id_cine) FROM stdin;
1	Sala IMAX 1	IMAX	Activa	1
2	IMAX PRUEBA - Sala 02	IMAX	Activa	1
3	IMAX PRUEBA - Sala 03	IMAX	Activa	1
4	IMAX PRUEBA - Sala 04	IMAX	Activa	1
5	IMAX PRUEBA - Sala 05	IMAX	Activa	1
6	IMAX PRUEBA - Sala 06	IMAX	Activa	1
7	IMAX PRUEBA - Sala 07	IMAX	Activa	1
8	IMAX PRUEBA - Sala 08	IMAX	Activa	1
9	IMAX PRUEBA - Sala 09	IMAX	Activa	1
10	IMAX PRUEBA - Sala 10	IMAX	Activa	1
\.


--
-- TOC entry 5044 (class 0 OID 25708)
-- Dependencies: 226
-- Data for Name: asiento; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.asiento (id_asiento, fila, numero, estado, id_sala) FROM stdin;
1	A	1	Disponible	1
2	A	2	Disponible	1
3	A	3	Disponible	1
4	A	4	Disponible	1
5	A	1	Disponible	2
6	B	1	Disponible	2
7	C	1	Disponible	2
8	D	1	Disponible	2
9	A	1	Disponible	3
10	B	1	Disponible	3
11	C	1	Disponible	3
12	D	1	Disponible	3
13	A	1	Disponible	4
14	B	1	Disponible	4
15	C	1	Disponible	4
16	D	1	Disponible	4
17	A	1	Disponible	5
18	B	1	Disponible	5
19	C	1	Disponible	5
20	D	1	Disponible	5
21	A	1	Disponible	6
22	B	1	Disponible	6
23	C	1	Disponible	6
24	D	1	Disponible	6
25	A	1	Disponible	7
26	B	1	Disponible	7
27	C	1	Disponible	7
28	D	1	Disponible	7
29	A	1	Disponible	8
30	B	1	Disponible	8
31	C	1	Disponible	8
32	D	1	Disponible	8
33	A	1	Disponible	9
34	B	1	Disponible	9
35	C	1	Disponible	9
36	D	1	Disponible	9
37	A	1	Disponible	10
38	B	1	Disponible	10
39	C	1	Disponible	10
40	D	1	Disponible	10
41	A	2	Disponible	2
42	B	2	Disponible	2
43	C	2	Disponible	2
44	D	2	Disponible	2
45	A	2	Disponible	3
46	B	2	Disponible	3
47	C	2	Disponible	3
48	D	2	Disponible	3
49	A	2	Disponible	4
50	B	2	Disponible	4
51	C	2	Disponible	4
52	D	2	Disponible	4
53	A	2	Disponible	5
54	B	2	Disponible	5
55	C	2	Disponible	5
56	D	2	Disponible	5
57	A	2	Disponible	6
58	B	2	Disponible	6
59	C	2	Disponible	6
60	D	2	Disponible	6
61	A	2	Disponible	7
62	B	2	Disponible	7
63	C	2	Disponible	7
64	D	2	Disponible	7
65	A	2	Disponible	8
66	B	2	Disponible	8
67	C	2	Disponible	8
68	D	2	Disponible	8
69	A	2	Disponible	9
70	B	2	Disponible	9
71	C	2	Disponible	9
72	D	2	Disponible	9
73	A	2	Disponible	10
74	B	2	Disponible	10
75	C	2	Disponible	10
76	D	2	Disponible	10
77	A	3	Disponible	2
78	B	3	Disponible	2
79	C	3	Disponible	2
80	D	3	Disponible	2
81	A	3	Disponible	3
82	B	3	Disponible	3
83	C	3	Disponible	3
84	D	3	Disponible	3
85	A	3	Disponible	4
86	B	3	Disponible	4
87	C	3	Disponible	4
88	D	3	Disponible	4
89	A	3	Disponible	5
90	B	3	Disponible	5
91	C	3	Disponible	5
92	D	3	Disponible	5
93	A	3	Disponible	6
94	B	3	Disponible	6
95	C	3	Disponible	6
96	D	3	Disponible	6
97	A	3	Disponible	7
98	B	3	Disponible	7
99	C	3	Disponible	7
100	D	3	Disponible	7
101	A	3	Disponible	8
102	B	3	Disponible	8
103	C	3	Disponible	8
104	D	3	Disponible	8
105	A	3	Disponible	9
106	B	3	Disponible	9
107	C	3	Disponible	9
108	D	3	Disponible	9
109	A	3	Disponible	10
110	B	3	Disponible	10
111	C	3	Disponible	10
112	D	3	Disponible	10
113	A	4	Disponible	2
114	B	4	Disponible	2
115	C	4	Disponible	2
116	D	4	Disponible	2
117	A	4	Disponible	3
118	B	4	Disponible	3
119	C	4	Disponible	3
120	D	4	Disponible	3
121	A	4	Disponible	4
122	B	4	Disponible	4
123	C	4	Disponible	4
124	D	4	Disponible	4
125	A	4	Disponible	5
126	B	4	Disponible	5
127	C	4	Disponible	5
128	D	4	Disponible	5
129	A	4	Disponible	6
130	B	4	Disponible	6
131	C	4	Disponible	6
132	D	4	Disponible	6
133	A	4	Disponible	7
134	B	4	Disponible	7
135	C	4	Disponible	7
136	D	4	Disponible	7
137	A	4	Disponible	8
138	B	4	Disponible	8
139	C	4	Disponible	8
140	D	4	Disponible	8
141	A	4	Disponible	9
142	B	4	Disponible	9
143	C	4	Disponible	9
144	D	4	Disponible	9
145	A	4	Disponible	10
146	B	4	Disponible	10
147	C	4	Disponible	10
148	D	4	Disponible	10
149	A	5	Disponible	2
150	B	5	Disponible	2
151	C	5	Disponible	2
152	D	5	Disponible	2
153	A	5	Disponible	3
154	B	5	Disponible	3
155	C	5	Disponible	3
156	D	5	Disponible	3
157	A	5	Disponible	4
158	B	5	Disponible	4
159	C	5	Disponible	4
160	D	5	Disponible	4
161	A	5	Disponible	5
162	B	5	Disponible	5
163	C	5	Disponible	5
164	D	5	Disponible	5
165	A	5	Disponible	6
166	B	5	Disponible	6
167	C	5	Disponible	6
168	D	5	Disponible	6
169	A	5	Disponible	7
170	B	5	Disponible	7
171	C	5	Disponible	7
172	D	5	Disponible	7
173	A	5	Disponible	8
174	B	5	Disponible	8
175	C	5	Disponible	8
176	D	5	Disponible	8
177	A	5	Disponible	9
178	B	5	Disponible	9
179	C	5	Disponible	9
180	D	5	Disponible	9
181	A	5	Disponible	10
182	B	5	Disponible	10
183	C	5	Disponible	10
184	D	5	Disponible	10
185	A	6	Disponible	2
186	B	6	Disponible	2
187	C	6	Disponible	2
188	D	6	Disponible	2
189	A	6	Disponible	3
190	B	6	Disponible	3
191	C	6	Disponible	3
192	D	6	Disponible	3
193	A	6	Disponible	4
194	B	6	Disponible	4
195	C	6	Disponible	4
196	D	6	Disponible	4
197	A	6	Disponible	5
198	B	6	Disponible	5
199	C	6	Disponible	5
200	D	6	Disponible	5
201	A	6	Disponible	6
202	B	6	Disponible	6
203	C	6	Disponible	6
204	D	6	Disponible	6
205	A	6	Disponible	7
206	B	6	Disponible	7
207	C	6	Disponible	7
208	D	6	Disponible	7
209	A	6	Disponible	8
210	B	6	Disponible	8
211	C	6	Disponible	8
212	D	6	Disponible	8
213	A	6	Disponible	9
214	B	6	Disponible	9
215	C	6	Disponible	9
216	D	6	Disponible	9
217	A	6	Disponible	10
218	B	6	Disponible	10
219	C	6	Disponible	10
220	D	6	Disponible	10
221	A	7	Disponible	2
222	B	7	Disponible	2
223	C	7	Disponible	2
224	D	7	Disponible	2
225	A	7	Disponible	3
226	B	7	Disponible	3
227	C	7	Disponible	3
228	D	7	Disponible	3
229	A	7	Disponible	4
230	B	7	Disponible	4
231	C	7	Disponible	4
232	D	7	Disponible	4
233	A	7	Disponible	5
234	B	7	Disponible	5
235	C	7	Disponible	5
236	D	7	Disponible	5
237	A	7	Disponible	6
238	B	7	Disponible	6
239	C	7	Disponible	6
240	D	7	Disponible	6
241	A	7	Disponible	7
242	B	7	Disponible	7
243	C	7	Disponible	7
244	D	7	Disponible	7
245	A	7	Disponible	8
246	B	7	Disponible	8
247	C	7	Disponible	8
248	D	7	Disponible	8
249	A	7	Disponible	9
250	B	7	Disponible	9
251	C	7	Disponible	9
252	D	7	Disponible	9
253	A	7	Disponible	10
254	B	7	Disponible	10
255	C	7	Disponible	10
256	D	7	Disponible	10
257	A	8	Disponible	2
258	B	8	Disponible	2
259	C	8	Disponible	2
260	D	8	Disponible	2
261	A	8	Disponible	3
262	B	8	Disponible	3
263	C	8	Disponible	3
264	D	8	Disponible	3
265	A	8	Disponible	4
266	B	8	Disponible	4
267	C	8	Disponible	4
268	D	8	Disponible	4
269	A	8	Disponible	5
270	B	8	Disponible	5
271	C	8	Disponible	5
272	D	8	Disponible	5
273	A	8	Disponible	6
274	B	8	Disponible	6
275	C	8	Disponible	6
276	D	8	Disponible	6
277	A	8	Disponible	7
278	B	8	Disponible	7
279	C	8	Disponible	7
280	D	8	Disponible	7
281	A	8	Disponible	8
282	B	8	Disponible	8
283	C	8	Disponible	8
284	D	8	Disponible	8
285	A	8	Disponible	9
286	B	8	Disponible	9
287	C	8	Disponible	9
288	D	8	Disponible	9
289	A	8	Disponible	10
290	B	8	Disponible	10
291	C	8	Disponible	10
292	D	8	Disponible	10
293	A	9	Disponible	2
294	B	9	Disponible	2
295	C	9	Disponible	2
296	D	9	Disponible	2
297	A	9	Disponible	3
298	B	9	Disponible	3
299	C	9	Disponible	3
300	D	9	Disponible	3
301	A	9	Disponible	4
302	B	9	Disponible	4
303	C	9	Disponible	4
304	D	9	Disponible	4
305	A	9	Disponible	5
306	B	9	Disponible	5
307	C	9	Disponible	5
308	D	9	Disponible	5
309	A	9	Disponible	6
310	B	9	Disponible	6
311	C	9	Disponible	6
312	D	9	Disponible	6
313	A	9	Disponible	7
314	B	9	Disponible	7
315	C	9	Disponible	7
316	D	9	Disponible	7
317	A	9	Disponible	8
318	B	9	Disponible	8
319	C	9	Disponible	8
320	D	9	Disponible	8
321	A	9	Disponible	9
322	B	9	Disponible	9
323	C	9	Disponible	9
324	D	9	Disponible	9
325	A	9	Disponible	10
326	B	9	Disponible	10
327	C	9	Disponible	10
328	D	9	Disponible	10
329	A	10	Disponible	2
330	B	10	Disponible	2
331	C	10	Disponible	2
332	D	10	Disponible	2
333	A	10	Disponible	3
334	B	10	Disponible	3
335	C	10	Disponible	3
336	D	10	Disponible	3
337	A	10	Disponible	4
338	B	10	Disponible	4
339	C	10	Disponible	4
340	D	10	Disponible	4
341	A	10	Disponible	5
342	B	10	Disponible	5
343	C	10	Disponible	5
344	D	10	Disponible	5
345	A	10	Disponible	6
346	B	10	Disponible	6
347	C	10	Disponible	6
348	D	10	Disponible	6
349	A	10	Disponible	7
350	B	10	Disponible	7
351	C	10	Disponible	7
352	D	10	Disponible	7
353	A	10	Disponible	8
354	B	10	Disponible	8
355	C	10	Disponible	8
356	D	10	Disponible	8
357	A	10	Disponible	9
358	B	10	Disponible	9
359	C	10	Disponible	9
360	D	10	Disponible	9
361	A	10	Disponible	10
362	B	10	Disponible	10
363	C	10	Disponible	10
364	D	10	Disponible	10
\.


--
-- TOC entry 5038 (class 0 OID 25661)
-- Dependencies: 220
-- Data for Name: pelicula; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pelicula (id_pelicula, titulo, sinopsis, duracion, clasificacion) FROM stdin;
1	Interestelar	Una misión espacial para explorar nuevos mundos.	169	PG-13
8	IMAX PRUEBA - Película 001	Película ficticia para pruebas de carga y reportes.	120	PG-13
9	IMAX PRUEBA - Película 002	Película ficticia para pruebas de carga y reportes.	120	PG-13
10	IMAX PRUEBA - Película 003	Película ficticia para pruebas de carga y reportes.	120	PG-13
11	IMAX PRUEBA - Película 004	Película ficticia para pruebas de carga y reportes.	120	PG-13
12	IMAX PRUEBA - Película 005	Película ficticia para pruebas de carga y reportes.	120	PG-13
13	IMAX PRUEBA - Película 006	Película ficticia para pruebas de carga y reportes.	120	PG-13
14	IMAX PRUEBA - Película 007	Película ficticia para pruebas de carga y reportes.	120	PG-13
15	IMAX PRUEBA - Película 008	Película ficticia para pruebas de carga y reportes.	120	PG-13
16	IMAX PRUEBA - Película 009	Película ficticia para pruebas de carga y reportes.	120	PG-13
17	IMAX PRUEBA - Película 010	Película ficticia para pruebas de carga y reportes.	120	PG-13
18	IMAX PRUEBA - Película 011	Película ficticia para pruebas de carga y reportes.	120	PG-13
19	IMAX PRUEBA - Película 012	Película ficticia para pruebas de carga y reportes.	120	PG-13
20	IMAX PRUEBA - Película 013	Película ficticia para pruebas de carga y reportes.	120	PG-13
21	IMAX PRUEBA - Película 014	Película ficticia para pruebas de carga y reportes.	120	PG-13
22	IMAX PRUEBA - Película 015	Película ficticia para pruebas de carga y reportes.	120	PG-13
23	IMAX PRUEBA - Película 016	Película ficticia para pruebas de carga y reportes.	120	PG-13
24	IMAX PRUEBA - Película 017	Película ficticia para pruebas de carga y reportes.	120	PG-13
25	IMAX PRUEBA - Película 018	Película ficticia para pruebas de carga y reportes.	120	PG-13
26	IMAX PRUEBA - Película 019	Película ficticia para pruebas de carga y reportes.	120	PG-13
27	IMAX PRUEBA - Película 020	Película ficticia para pruebas de carga y reportes.	120	PG-13
28	IMAX PRUEBA - Película 021	Película ficticia para pruebas de carga y reportes.	120	PG-13
29	IMAX PRUEBA - Película 022	Película ficticia para pruebas de carga y reportes.	120	PG-13
30	IMAX PRUEBA - Película 023	Película ficticia para pruebas de carga y reportes.	120	PG-13
31	IMAX PRUEBA - Película 024	Película ficticia para pruebas de carga y reportes.	120	PG-13
32	IMAX PRUEBA - Película 025	Película ficticia para pruebas de carga y reportes.	120	PG-13
33	IMAX PRUEBA - Película 026	Película ficticia para pruebas de carga y reportes.	120	PG-13
34	IMAX PRUEBA - Película 027	Película ficticia para pruebas de carga y reportes.	120	PG-13
35	IMAX PRUEBA - Película 028	Película ficticia para pruebas de carga y reportes.	120	PG-13
36	IMAX PRUEBA - Película 029	Película ficticia para pruebas de carga y reportes.	120	PG-13
37	IMAX PRUEBA - Película 030	Película ficticia para pruebas de carga y reportes.	120	PG-13
38	IMAX PRUEBA - Película 031	Película ficticia para pruebas de carga y reportes.	120	PG-13
39	IMAX PRUEBA - Película 032	Película ficticia para pruebas de carga y reportes.	120	PG-13
40	IMAX PRUEBA - Película 033	Película ficticia para pruebas de carga y reportes.	120	PG-13
41	IMAX PRUEBA - Película 034	Película ficticia para pruebas de carga y reportes.	120	PG-13
42	IMAX PRUEBA - Película 035	Película ficticia para pruebas de carga y reportes.	120	PG-13
43	IMAX PRUEBA - Película 036	Película ficticia para pruebas de carga y reportes.	120	PG-13
44	IMAX PRUEBA - Película 037	Película ficticia para pruebas de carga y reportes.	120	PG-13
45	IMAX PRUEBA - Película 038	Película ficticia para pruebas de carga y reportes.	120	PG-13
46	IMAX PRUEBA - Película 039	Película ficticia para pruebas de carga y reportes.	120	PG-13
47	IMAX PRUEBA - Película 040	Película ficticia para pruebas de carga y reportes.	120	PG-13
48	IMAX PRUEBA - Película 041	Película ficticia para pruebas de carga y reportes.	120	PG-13
49	IMAX PRUEBA - Película 042	Película ficticia para pruebas de carga y reportes.	120	PG-13
50	IMAX PRUEBA - Película 043	Película ficticia para pruebas de carga y reportes.	120	PG-13
51	IMAX PRUEBA - Película 044	Película ficticia para pruebas de carga y reportes.	120	PG-13
52	IMAX PRUEBA - Película 045	Película ficticia para pruebas de carga y reportes.	120	PG-13
53	IMAX PRUEBA - Película 046	Película ficticia para pruebas de carga y reportes.	120	PG-13
54	IMAX PRUEBA - Película 047	Película ficticia para pruebas de carga y reportes.	120	PG-13
55	IMAX PRUEBA - Película 048	Película ficticia para pruebas de carga y reportes.	120	PG-13
56	IMAX PRUEBA - Película 049	Película ficticia para pruebas de carga y reportes.	120	PG-13
\.


--
-- TOC entry 5046 (class 0 OID 25728)
-- Dependencies: 228
-- Data for Name: funcion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.funcion (id_funcion, fecha_inicio, fecha_fin, estado, id_pelicula, id_sala) FROM stdin;
1	2026-10-27 20:08:17.96117-06	2026-10-27 23:08:17.96117-06	Programada	1	1
6	2026-10-23 23:38:36.240164-06	2026-10-24 02:38:36.240491-06	programada	1	1
7	2026-11-01 14:00:00-06	2026-11-01 17:00:00-06	programada	8	2
8	2026-11-02 14:00:00-06	2026-11-02 17:00:00-06	programada	9	2
9	2026-11-03 14:00:00-06	2026-11-03 17:00:00-06	programada	10	2
10	2026-11-04 14:00:00-06	2026-11-04 17:00:00-06	programada	11	2
11	2026-11-05 14:00:00-06	2026-11-05 17:00:00-06	programada	12	2
12	2026-11-06 14:00:00-06	2026-11-06 17:00:00-06	programada	13	2
13	2026-11-07 14:00:00-06	2026-11-07 17:00:00-06	programada	14	2
14	2026-11-08 14:00:00-06	2026-11-08 17:00:00-06	programada	15	2
15	2026-11-09 14:00:00-06	2026-11-09 17:00:00-06	programada	16	2
16	2026-11-10 14:00:00-06	2026-11-10 17:00:00-06	programada	17	2
17	2026-11-11 14:00:00-06	2026-11-11 17:00:00-06	programada	18	2
18	2026-11-12 14:00:00-06	2026-11-12 17:00:00-06	programada	19	2
19	2026-11-13 14:00:00-06	2026-11-13 17:00:00-06	programada	20	2
20	2026-11-14 14:00:00-06	2026-11-14 17:00:00-06	programada	21	2
21	2026-11-15 14:00:00-06	2026-11-15 17:00:00-06	programada	22	2
22	2026-11-16 14:00:00-06	2026-11-16 17:00:00-06	programada	23	2
23	2026-11-17 14:00:00-06	2026-11-17 17:00:00-06	programada	24	2
24	2026-11-18 14:00:00-06	2026-11-18 17:00:00-06	programada	25	2
25	2026-11-19 14:00:00-06	2026-11-19 17:00:00-06	programada	26	2
26	2026-11-20 14:00:00-06	2026-11-20 17:00:00-06	programada	27	2
27	2026-11-01 14:00:00-06	2026-11-01 17:00:00-06	programada	28	3
28	2026-11-02 14:00:00-06	2026-11-02 17:00:00-06	programada	29	3
29	2026-11-03 14:00:00-06	2026-11-03 17:00:00-06	programada	30	3
30	2026-11-04 14:00:00-06	2026-11-04 17:00:00-06	programada	31	3
31	2026-11-05 14:00:00-06	2026-11-05 17:00:00-06	programada	32	3
32	2026-11-06 14:00:00-06	2026-11-06 17:00:00-06	programada	33	3
33	2026-11-07 14:00:00-06	2026-11-07 17:00:00-06	programada	34	3
34	2026-11-08 14:00:00-06	2026-11-08 17:00:00-06	programada	35	3
35	2026-11-09 14:00:00-06	2026-11-09 17:00:00-06	programada	36	3
36	2026-11-10 14:00:00-06	2026-11-10 17:00:00-06	programada	37	3
37	2026-11-11 14:00:00-06	2026-11-11 17:00:00-06	programada	38	3
38	2026-11-12 14:00:00-06	2026-11-12 17:00:00-06	programada	39	3
39	2026-11-13 14:00:00-06	2026-11-13 17:00:00-06	programada	40	3
40	2026-11-14 14:00:00-06	2026-11-14 17:00:00-06	programada	41	3
41	2026-11-15 14:00:00-06	2026-11-15 17:00:00-06	programada	42	3
42	2026-11-16 14:00:00-06	2026-11-16 17:00:00-06	programada	43	3
43	2026-11-17 14:00:00-06	2026-11-17 17:00:00-06	programada	44	3
44	2026-11-18 14:00:00-06	2026-11-18 17:00:00-06	programada	45	3
45	2026-11-19 14:00:00-06	2026-11-19 17:00:00-06	programada	46	3
46	2026-11-20 14:00:00-06	2026-11-20 17:00:00-06	programada	47	3
47	2026-11-01 14:00:00-06	2026-11-01 17:00:00-06	programada	48	4
48	2026-11-02 14:00:00-06	2026-11-02 17:00:00-06	programada	49	4
49	2026-11-03 14:00:00-06	2026-11-03 17:00:00-06	programada	50	4
50	2026-11-04 14:00:00-06	2026-11-04 17:00:00-06	programada	51	4
51	2026-11-05 14:00:00-06	2026-11-05 17:00:00-06	programada	52	4
52	2026-11-06 14:00:00-06	2026-11-06 17:00:00-06	programada	53	4
53	2026-11-07 14:00:00-06	2026-11-07 17:00:00-06	programada	54	4
54	2026-11-08 14:00:00-06	2026-11-08 17:00:00-06	programada	55	4
55	2026-11-09 14:00:00-06	2026-11-09 17:00:00-06	programada	56	4
56	2026-11-10 14:00:00-06	2026-11-10 17:00:00-06	programada	8	4
57	2026-11-11 14:00:00-06	2026-11-11 17:00:00-06	programada	9	4
58	2026-11-12 14:00:00-06	2026-11-12 17:00:00-06	programada	10	4
59	2026-11-13 14:00:00-06	2026-11-13 17:00:00-06	programada	11	4
60	2026-11-14 14:00:00-06	2026-11-14 17:00:00-06	programada	12	4
61	2026-11-15 14:00:00-06	2026-11-15 17:00:00-06	programada	13	4
62	2026-11-16 14:00:00-06	2026-11-16 17:00:00-06	programada	14	4
63	2026-11-17 14:00:00-06	2026-11-17 17:00:00-06	programada	15	4
64	2026-11-18 14:00:00-06	2026-11-18 17:00:00-06	programada	16	4
65	2026-11-19 14:00:00-06	2026-11-19 17:00:00-06	programada	17	4
66	2026-11-20 14:00:00-06	2026-11-20 17:00:00-06	programada	18	4
67	2026-11-01 14:00:00-06	2026-11-01 17:00:00-06	programada	19	5
68	2026-11-02 14:00:00-06	2026-11-02 17:00:00-06	programada	20	5
69	2026-11-03 14:00:00-06	2026-11-03 17:00:00-06	programada	21	5
70	2026-11-04 14:00:00-06	2026-11-04 17:00:00-06	programada	22	5
71	2026-11-05 14:00:00-06	2026-11-05 17:00:00-06	programada	23	5
72	2026-11-06 14:00:00-06	2026-11-06 17:00:00-06	programada	24	5
73	2026-11-07 14:00:00-06	2026-11-07 17:00:00-06	programada	25	5
74	2026-11-08 14:00:00-06	2026-11-08 17:00:00-06	programada	26	5
75	2026-11-09 14:00:00-06	2026-11-09 17:00:00-06	programada	27	5
76	2026-11-10 14:00:00-06	2026-11-10 17:00:00-06	programada	28	5
77	2026-11-11 14:00:00-06	2026-11-11 17:00:00-06	programada	29	5
78	2026-11-12 14:00:00-06	2026-11-12 17:00:00-06	programada	30	5
79	2026-11-13 14:00:00-06	2026-11-13 17:00:00-06	programada	31	5
80	2026-11-14 14:00:00-06	2026-11-14 17:00:00-06	programada	32	5
81	2026-11-15 14:00:00-06	2026-11-15 17:00:00-06	programada	33	5
82	2026-11-16 14:00:00-06	2026-11-16 17:00:00-06	programada	34	5
83	2026-11-17 14:00:00-06	2026-11-17 17:00:00-06	programada	35	5
84	2026-11-18 14:00:00-06	2026-11-18 17:00:00-06	programada	36	5
85	2026-11-19 14:00:00-06	2026-11-19 17:00:00-06	programada	37	5
86	2026-11-20 14:00:00-06	2026-11-20 17:00:00-06	programada	38	5
87	2026-11-01 14:00:00-06	2026-11-01 17:00:00-06	programada	39	6
88	2026-11-02 14:00:00-06	2026-11-02 17:00:00-06	programada	40	6
89	2026-11-03 14:00:00-06	2026-11-03 17:00:00-06	programada	41	6
90	2026-11-04 14:00:00-06	2026-11-04 17:00:00-06	programada	42	6
91	2026-11-05 14:00:00-06	2026-11-05 17:00:00-06	programada	43	6
92	2026-11-06 14:00:00-06	2026-11-06 17:00:00-06	programada	44	6
93	2026-11-07 14:00:00-06	2026-11-07 17:00:00-06	programada	45	6
94	2026-11-08 14:00:00-06	2026-11-08 17:00:00-06	programada	46	6
95	2026-11-09 14:00:00-06	2026-11-09 17:00:00-06	programada	47	6
96	2026-11-10 14:00:00-06	2026-11-10 17:00:00-06	programada	48	6
97	2026-11-11 14:00:00-06	2026-11-11 17:00:00-06	programada	49	6
98	2026-11-12 14:00:00-06	2026-11-12 17:00:00-06	programada	50	6
99	2026-11-13 14:00:00-06	2026-11-13 17:00:00-06	programada	51	6
100	2026-11-14 14:00:00-06	2026-11-14 17:00:00-06	programada	52	6
101	2026-11-15 14:00:00-06	2026-11-15 17:00:00-06	programada	53	6
102	2026-11-16 14:00:00-06	2026-11-16 17:00:00-06	programada	54	6
103	2026-11-17 14:00:00-06	2026-11-17 17:00:00-06	programada	55	6
104	2026-11-18 14:00:00-06	2026-11-18 17:00:00-06	programada	56	6
105	2026-11-19 14:00:00-06	2026-11-19 17:00:00-06	programada	8	6
106	2026-11-20 14:00:00-06	2026-11-20 17:00:00-06	programada	9	6
107	2026-11-01 14:00:00-06	2026-11-01 17:00:00-06	programada	10	7
108	2026-11-02 14:00:00-06	2026-11-02 17:00:00-06	programada	11	7
109	2026-11-03 14:00:00-06	2026-11-03 17:00:00-06	programada	12	7
110	2026-11-04 14:00:00-06	2026-11-04 17:00:00-06	programada	13	7
111	2026-11-05 14:00:00-06	2026-11-05 17:00:00-06	programada	14	7
112	2026-11-06 14:00:00-06	2026-11-06 17:00:00-06	programada	15	7
113	2026-11-07 14:00:00-06	2026-11-07 17:00:00-06	programada	16	7
114	2026-11-08 14:00:00-06	2026-11-08 17:00:00-06	programada	17	7
115	2026-11-09 14:00:00-06	2026-11-09 17:00:00-06	programada	18	7
116	2026-11-10 14:00:00-06	2026-11-10 17:00:00-06	programada	19	7
117	2026-11-11 14:00:00-06	2026-11-11 17:00:00-06	programada	20	7
118	2026-11-12 14:00:00-06	2026-11-12 17:00:00-06	programada	21	7
119	2026-11-13 14:00:00-06	2026-11-13 17:00:00-06	programada	22	7
120	2026-11-14 14:00:00-06	2026-11-14 17:00:00-06	programada	23	7
121	2026-11-15 14:00:00-06	2026-11-15 17:00:00-06	programada	24	7
122	2026-11-16 14:00:00-06	2026-11-16 17:00:00-06	programada	25	7
123	2026-11-17 14:00:00-06	2026-11-17 17:00:00-06	programada	26	7
124	2026-11-18 14:00:00-06	2026-11-18 17:00:00-06	programada	27	7
125	2026-11-19 14:00:00-06	2026-11-19 17:00:00-06	programada	28	7
126	2026-11-20 14:00:00-06	2026-11-20 17:00:00-06	programada	29	7
127	2026-11-01 14:00:00-06	2026-11-01 17:00:00-06	programada	30	8
128	2026-11-02 14:00:00-06	2026-11-02 17:00:00-06	programada	31	8
129	2026-11-03 14:00:00-06	2026-11-03 17:00:00-06	programada	32	8
130	2026-11-04 14:00:00-06	2026-11-04 17:00:00-06	programada	33	8
131	2026-11-05 14:00:00-06	2026-11-05 17:00:00-06	programada	34	8
132	2026-11-06 14:00:00-06	2026-11-06 17:00:00-06	programada	35	8
133	2026-11-07 14:00:00-06	2026-11-07 17:00:00-06	programada	36	8
134	2026-11-08 14:00:00-06	2026-11-08 17:00:00-06	programada	37	8
135	2026-11-09 14:00:00-06	2026-11-09 17:00:00-06	programada	38	8
136	2026-11-10 14:00:00-06	2026-11-10 17:00:00-06	programada	39	8
137	2026-11-11 14:00:00-06	2026-11-11 17:00:00-06	programada	40	8
138	2026-11-12 14:00:00-06	2026-11-12 17:00:00-06	programada	41	8
139	2026-11-13 14:00:00-06	2026-11-13 17:00:00-06	programada	42	8
140	2026-11-14 14:00:00-06	2026-11-14 17:00:00-06	programada	43	8
141	2026-11-15 14:00:00-06	2026-11-15 17:00:00-06	programada	44	8
142	2026-11-16 14:00:00-06	2026-11-16 17:00:00-06	programada	45	8
143	2026-11-17 14:00:00-06	2026-11-17 17:00:00-06	programada	46	8
144	2026-11-18 14:00:00-06	2026-11-18 17:00:00-06	programada	47	8
145	2026-11-19 14:00:00-06	2026-11-19 17:00:00-06	programada	48	8
146	2026-11-20 14:00:00-06	2026-11-20 17:00:00-06	programada	49	8
147	2026-11-01 14:00:00-06	2026-11-01 17:00:00-06	programada	50	9
148	2026-11-02 14:00:00-06	2026-11-02 17:00:00-06	programada	51	9
149	2026-11-03 14:00:00-06	2026-11-03 17:00:00-06	programada	52	9
150	2026-11-04 14:00:00-06	2026-11-04 17:00:00-06	programada	53	9
151	2026-11-05 14:00:00-06	2026-11-05 17:00:00-06	programada	54	9
152	2026-11-06 14:00:00-06	2026-11-06 17:00:00-06	programada	55	9
153	2026-11-07 14:00:00-06	2026-11-07 17:00:00-06	programada	56	9
154	2026-11-08 14:00:00-06	2026-11-08 17:00:00-06	programada	8	9
155	2026-11-09 14:00:00-06	2026-11-09 17:00:00-06	programada	9	9
156	2026-11-10 14:00:00-06	2026-11-10 17:00:00-06	programada	10	9
157	2026-11-11 14:00:00-06	2026-11-11 17:00:00-06	programada	11	9
158	2026-11-12 14:00:00-06	2026-11-12 17:00:00-06	programada	12	9
159	2026-11-13 14:00:00-06	2026-11-13 17:00:00-06	programada	13	9
160	2026-11-14 14:00:00-06	2026-11-14 17:00:00-06	programada	14	9
161	2026-11-15 14:00:00-06	2026-11-15 17:00:00-06	programada	15	9
162	2026-11-16 14:00:00-06	2026-11-16 17:00:00-06	programada	16	9
163	2026-11-17 14:00:00-06	2026-11-17 17:00:00-06	programada	17	9
164	2026-11-18 14:00:00-06	2026-11-18 17:00:00-06	programada	18	9
165	2026-11-19 14:00:00-06	2026-11-19 17:00:00-06	programada	19	9
166	2026-11-20 14:00:00-06	2026-11-20 17:00:00-06	programada	20	9
167	2026-11-01 14:00:00-06	2026-11-01 17:00:00-06	programada	21	10
168	2026-11-02 14:00:00-06	2026-11-02 17:00:00-06	programada	22	10
169	2026-11-03 14:00:00-06	2026-11-03 17:00:00-06	programada	23	10
170	2026-11-04 14:00:00-06	2026-11-04 17:00:00-06	programada	24	10
171	2026-11-05 14:00:00-06	2026-11-05 17:00:00-06	programada	25	10
172	2026-11-06 14:00:00-06	2026-11-06 17:00:00-06	programada	26	10
173	2026-11-07 14:00:00-06	2026-11-07 17:00:00-06	programada	27	10
174	2026-11-08 14:00:00-06	2026-11-08 17:00:00-06	programada	28	10
175	2026-11-09 14:00:00-06	2026-11-09 17:00:00-06	programada	29	10
176	2026-11-10 14:00:00-06	2026-11-10 17:00:00-06	programada	30	10
177	2026-11-11 14:00:00-06	2026-11-11 17:00:00-06	programada	31	10
178	2026-11-12 14:00:00-06	2026-11-12 17:00:00-06	programada	32	10
179	2026-11-13 14:00:00-06	2026-11-13 17:00:00-06	programada	33	10
180	2026-11-14 14:00:00-06	2026-11-14 17:00:00-06	programada	34	10
181	2026-11-15 14:00:00-06	2026-11-15 17:00:00-06	programada	35	10
182	2026-11-16 14:00:00-06	2026-11-16 17:00:00-06	programada	36	10
183	2026-11-17 14:00:00-06	2026-11-17 17:00:00-06	programada	37	10
184	2026-11-18 14:00:00-06	2026-11-18 17:00:00-06	programada	38	10
185	2026-11-19 14:00:00-06	2026-11-19 17:00:00-06	programada	39	10
186	2026-11-20 14:00:00-06	2026-11-20 17:00:00-06	programada	40	10
\.


--
-- TOC entry 5048 (class 0 OID 25810)
-- Dependencies: 235
-- Data for Name: tarifa; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tarifa (id_tarifa, nombre, descripcion, precio_base, estado) FROM stdin;
1	Entrada General IMAX	Tarifa general para funciones IMAX	6000.00	Activa
\.


--
-- TOC entry 5054 (class 0 OID 0)
-- Dependencies: 225
-- Name: asiento_id_asiento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.asiento_id_asiento_seq', 364, true);


--
-- TOC entry 5055 (class 0 OID 0)
-- Dependencies: 221
-- Name: cine_id_cine_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cine_id_cine_seq', 1, true);


--
-- TOC entry 5056 (class 0 OID 0)
-- Dependencies: 227
-- Name: funcion_id_funcion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.funcion_id_funcion_seq', 186, true);


--
-- TOC entry 5057 (class 0 OID 0)
-- Dependencies: 219
-- Name: pelicula_id_pelicula_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pelicula_id_pelicula_seq', 56, true);


--
-- TOC entry 5058 (class 0 OID 0)
-- Dependencies: 223
-- Name: sala_id_sala_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sala_id_sala_seq', 10, true);


--
-- TOC entry 5059 (class 0 OID 0)
-- Dependencies: 234
-- Name: tarifa_id_tarifa_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tarifa_id_tarifa_seq', 1, true);


-- Completed on 2026-10-24 03:54:14

--
-- PostgreSQL database dump complete
--

\unrestrict ibw2I1NbZjZhZ7F71MyPjIkzP9wQcSbvmjJXhrODe83QhHnlUA24DdJKbjduTmZ

