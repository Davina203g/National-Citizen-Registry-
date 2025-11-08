
SET SERVEROUTPUT ON;

DECLARE
  -----------------------------------------------------------------
  -- STEP 1: Define the RECORD structure for a Citizen
  -----------------------------------------------------------------
  TYPE citizen_rec IS RECORD (
    national_id   VARCHAR2(20),
    full_name     VARCHAR2(100),
    date_of_birth DATE,
    province      VARCHAR2(50),
    contact_nums  SYS.VARRAY(3) OF VARCHAR2(15)  -- VARRAY for up to 3 phone numbers
  );

  -----------------------------------------------------------------
  -- STEP 2: Define COLLECTION types
  -----------------------------------------------------------------
  -- Associative Array: key-value lookup by national_id
  TYPE citizen_map_t IS TABLE OF citizen_rec INDEX BY VARCHAR2(20);

  -- Nested Table: dynamic list of citizens by province
  TYPE citizen_list_t IS TABLE OF citizen_rec;

  -----------------------------------------------------------------
  -- STEP 3: Declare variables
  -----------------------------------------------------------------
  g_registry      citizen_map_t;           -- main registry
  v_province_list citizen_list_t := citizen_list_t();  -- for filtered results
  v_temp          citizen_rec;             -- temporary holder
  v_action        VARCHAR2(10) := 'SEARCH';-- can be 'ADD', 'SEARCH', or 'LIST'
  v_input_id      VARCHAR2(20) := '1182111234567';
  v_input_prov    VARCHAR2(50) := 'Kigali';
  v_counter       PLS_INTEGER := 0;

BEGIN
  DBMS_OUTPUT.PUT_LINE('=== National Citizen Registry (Simplified & Complete) ===');
  DBMS_OUTPUT.PUT_LINE('');

  -----------------------------------------------------------------
  -- STEP 4: Load sample data into the registry
  -----------------------------------------------------------------
  v_temp.national_id   := '1182111234567';
  v_temp.full_name     := 'Alice Uwase';
  v_temp.date_of_birth := TO_DATE('1990-05-15','YYYY-MM-DD');
  v_temp.province      := 'Kigali';
  v_temp.contact_nums  := SYS.VARRAY(3)( '0788888888', '0722222222', '0799999999' );
  g_registry(v_temp.national_id) := v_temp;

  v_temp.national_id   := '1182111765432';
  v_temp.full_name     := 'Bob Gatore';
  v_temp.date_of_birth := TO_DATE('1985-08-22','YYYY-MM-DD');
  v_temp.province      := 'Musanze';
  v_temp.contact_nums  := SYS.VARRAY(3)( '0788111222', NULL, NULL );
  g_registry(v_temp.national_id) := v_temp;

  v_temp.national_id   := '1182111987654';
  v_temp.full_name     := 'Claire Mukamana';
  v_temp.date_of_birth := TO_DATE('1992-11-30','YYYY-MM-DD');
  v_temp.province      := 'Kigali';
  v_temp.contact_nums  := SYS.VARRAY(3)( '0788123456', '0788765432', NULL );
  g_registry(v_temp.national_id) := v_temp;

  DBMS_OUTPUT.PUT_LINE('Sample citizens loaded successfully.');
  DBMS_OUTPUT.PUT_LINE('');

  -----------------------------------------------------------------
  -- STEP 5: Search a citizen by ID (Associative Array + Record)
  -----------------------------------------------------------------
  IF v_action = 'SEARCH' THEN
    DBMS_OUTPUT.PUT_LINE('Searching for citizen ID: ' || v_input_id);

    IF g_registry.EXISTS(v_input_id) THEN
      v_temp := g_registry(v_input_id);
      DBMS_OUTPUT.PUT_LINE('FOUND:');
      DBMS_OUTPUT.PUT_LINE('  Name: ' || v_temp.full_name);
      DBMS_OUTPUT.PUT_LINE('  Province: ' || v_temp.province);
      DBMS_OUTPUT.PUT_LINE('  Date of Birth: ' || TO_CHAR(v_temp.date_of_birth,'YYYY-MM-DD'));

      -- Display contact numbers from VARRAY
      IF v_temp.contact_nums.COUNT > 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Contact Numbers:');
        FOR i IN 1 .. v_temp.contact_nums.COUNT LOOP
          IF v_temp.contact_nums(i) IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('    #' || i || ': ' || v_temp.contact_nums(i));
          END IF;
        END LOOP;
      END IF;
    ELSE
      DBMS_OUTPUT.PUT_LINE('Citizen ID not found. Jumping to error handler...');
      GOTO not_found;
    END IF;
    DBMS_OUTPUT.PUT_LINE('');
  END IF;

  -----------------------------------------------------------------
  -- STEP 6: List all citizens by province (Nested Table)
  -----------------------------------------------------------------
  DBMS_OUTPUT.PUT_LINE('Listing all citizens in province: ' || v_input_prov);
  v_province_list.DELETE;
  v_counter := 0;

  DECLARE
    idx VARCHAR2(20);
  BEGIN
    idx := g_registry.FIRST;
    WHILE idx IS NOT NULL LOOP
      IF g_registry(idx).province = v_input_prov THEN
        v_counter := v_counter + 1;
        v_province_list.EXTEND;
        v_province_list(v_counter) := g_registry(idx);
      END IF;
      idx := g_registry.NEXT(idx);
    END LOOP;
  END;

  IF v_province_list.COUNT = 0 THEN
    DBMS_OUTPUT.PUT_LINE('No citizens found in ' || v_input_prov);
    GOTO not_found;
  ELSE
    FOR i IN 1 .. v_province_list.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('  ' || i || '. ' || v_province_list(i).full_name ||
                           ' (' || v_province_list(i).national_id || ')');
    END LOOP;
  END IF;

  GOTO finish;

  -----------------------------------------------------------------
  -- STEP 7: GOTO HANDLERS
  -----------------------------------------------------------------
  <<not_found>>
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('*** Notice: Requested citizen or province not found. ***');

  <<finish>>
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('=== Registry Operation Complete ===');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;
/
