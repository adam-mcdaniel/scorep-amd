#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/types.h>

#include "papi.h"
#include "papi_internal.h"
#include "papi_vector.h"
#include "papi_memory.h"

//#define LSEEK
// #define READALL
#define ENERGYZERO
#include "linux-coretemp.h"


#define REFRESH_LAT 100000
#define INVALID_RESULT -1000000L

papi_vector_t _coretemp_vector;

struct temp_event {
    char name[PAPI_MAX_STR_LEN];
    char units[PAPI_MIN_STR_LEN];
    char description[PAPI_MAX_STR_LEN];
    char location[PAPI_MAX_STR_LEN];
    char path[PATH_MAX];
    long count;
    struct temp_event *next;
};

static CORETEMP_native_event_entry_t *_coretemp_native_events;
static int num_events = 0;
static int is_initialized = 0;

static struct temp_event *root = NULL;
static struct temp_event *last = NULL;

#define HANDLE_STRING_ERROR {fprintf(stderr,"%s:%i unexpected string function error.\n",__FILE__,__LINE__); exit(-1);}

static int insert_in_list(char *name, char *units, char *description, char *filename) {
    struct temp_event *temp = (struct temp_event *)papi_calloc(1, sizeof(struct temp_event));
    if (temp == NULL) {
        PAPIERROR("out of memory!");
        return PAPI_ENOMEM;
    }

    temp->next = NULL;

    if (root == NULL) {
        root = temp;
    } else if (last) {
        last->next = temp;
    } else {
        free(temp);
        PAPIERROR("This shouldn't be possible\n");
        return PAPI_ECMP;
    }

    last = temp;

    snprintf(temp->name, PAPI_MAX_STR_LEN, "%s", name);
    snprintf(temp->units, PAPI_MIN_STR_LEN, "%s", units);
    snprintf(temp->description, PAPI_MAX_STR_LEN, "%s", description);
    snprintf(temp->path, PATH_MAX, "%s", filename);

    return PAPI_OK;
}

static int generateEventList(char *base_dir) {
    char path[PATH_MAX], filename[PATH_MAX];
    char modulename[PAPI_MIN_STR_LEN], location[PAPI_MIN_STR_LEN], units[PAPI_MIN_STR_LEN], description[PAPI_MAX_STR_LEN], name[PAPI_MAX_STR_LEN];
    DIR *dir, *d;
    struct dirent *hwmonx;
    FILE *fff;
    int count = 0;
    int i, pathnum;
    int retlen;

#define NUM_PATHS 2
    char paths[NUM_PATHS][PATH_MAX] = {"device", "."};

    dir = opendir(base_dir);
    if (dir == NULL) {
        SUBDBG("Can't find %s, are you sure the coretemp module is loaded?\n", base_dir);
        return 0;
    }

    while ((hwmonx = readdir(dir))) {
        if (!strncmp("hwmon", hwmonx->d_name, 5)) {
            for (pathnum = 0; pathnum < NUM_PATHS; pathnum++) {
                retlen = snprintf(path, PATH_MAX, "%s/%s/%s", base_dir, hwmonx->d_name, paths[pathnum]);
                if (retlen <= 0 || PATH_MAX <= retlen) {
                    SUBDBG("Path length is too long.\n");
                    return PAPI_EINVAL;
                }
                SUBDBG("Trying to open %s\n", path);
                d = opendir(path);
                if (d == NULL) {
                    continue;
                }

                retlen = snprintf(filename, PAPI_MAX_STR_LEN, "%s/name", path);
                if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                    SUBDBG("Module name too long.\n");
                    return PAPI_EINVAL;
                }
                fff = fopen(filename, "r");
                if (fff == NULL) {
                    snprintf(modulename, PAPI_MIN_STR_LEN, "Unknown");
                } else {
                    if (fgets(modulename, PAPI_MIN_STR_LEN, fff) != NULL) {
                        modulename[strlen(modulename) - 1] = '\0';
                    }
                    fclose(fff);
                }

                SUBDBG("Found module %s\n", modulename);

                for (i = 0; i < 32; i++) {
                    retlen = snprintf(filename, PAPI_MAX_STR_LEN, "%s/in%d_label", path, i);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("Failed to construct location label.\n");
                        return PAPI_EINVAL;
                    }
                    fff = fopen(filename, "r");
                    if (fff == NULL) {
                        strncpy(location, "?", PAPI_MIN_STR_LEN);
                    } else {
                        if (fgets(location, PAPI_MIN_STR_LEN, fff) != NULL) {
                            location[strlen(location) - 1] = '\0';
                        }
                        fclose(fff);
                    }

                    retlen = snprintf(filename, PAPI_MAX_STR_LEN, "%s/in%d_input", path, i);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("Failed input temperature string.\n");
                        return PAPI_EINVAL;
                    }
                    fff = fopen(filename, "r");
                    if (fff == NULL) continue;
                    fclose(fff);

                    retlen = snprintf(name, PAPI_MAX_STR_LEN, "%s:in%i_input", hwmonx->d_name, i);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("Unable to generate name %s:in%i_input\n", hwmonx->d_name, i);
                        closedir(dir);
                        closedir(d);
                        return (PAPI_EINVAL);
                    }

                    snprintf(units, PAPI_MIN_STR_LEN, "V");
                    retlen = snprintf(description, PAPI_MAX_STR_LEN, "%s, %s module, label %s", units, modulename, location);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("snprintf failed.\n");
                        return PAPI_EINVAL;
                    }

                    if (insert_in_list(name, units, description, filename) != PAPI_OK) {
                        goto done_error;
                    }

                    count++;
                }

                for (i = 0; i < 32; i++) {
                    retlen = snprintf(filename, PAPI_MAX_STR_LEN, "%s/temp%d_label", path, i);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("Location label string failed.\n");
                        return PAPI_EINVAL;
                    }
                    fff = fopen(filename, "r");
                    if (fff == NULL) {
                        strncpy(location, "?", PAPI_MIN_STR_LEN);
                    } else {
                        if (fgets(location, PAPI_MIN_STR_LEN, fff) != NULL) {
                            location[strlen(location) - 1] = '\0';
                        }
                        fclose(fff);
                    }

                    retlen = snprintf(filename, PAPI_MAX_STR_LEN, "%s/temp%d_input", path, i);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("Input temperature string failed.\n");
                        return PAPI_EINVAL;
                    }
                    fff = fopen(filename, "r");
                    if (fff == NULL) continue;
                    fclose(fff);

                    retlen = snprintf(name, PAPI_MAX_STR_LEN, "%s:temp%i_input", hwmonx->d_name, i);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("Unable to generate name %s:temp%i_input\n", hwmonx->d_name, i);
                        closedir(d);
                        closedir(dir);
                        return (PAPI_EINVAL);
                    }

                    snprintf(units, PAPI_MIN_STR_LEN, "degrees C");
                    retlen = snprintf(description, PAPI_MAX_STR_LEN, "%s, %s module, label %s", units, modulename, location);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("snprintf failed.\n");
                        return PAPI_EINVAL;
                    }

                    if (insert_in_list(name, units, description, filename) != PAPI_OK) {
                        goto done_error;
                    }

                    count++;
                }


                for (i = 0; i < 32; i++) {
                    retlen = snprintf(filename, PAPI_MAX_STR_LEN, "%s/power%d_label", path, i);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("Location label string failed.\n");
                        return PAPI_EINVAL;
                    }
                    fff = fopen(filename, "r");
                    if (fff == NULL) {
                        strncpy(location, "?", PAPI_MIN_STR_LEN);
                    } else {
                        if (fgets(location, PAPI_MIN_STR_LEN, fff) != NULL) {
                            location[strlen(location) - 1] = '\0';
                        }
                        fclose(fff);
                    }

                    retlen = snprintf(filename, PAPI_MAX_STR_LEN, "%s/power%d_input", path, i);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("Input temperature string failed.\n");
                        return PAPI_EINVAL;
                    }
                    fff = fopen(filename, "r");
                    if (fff == NULL) continue;
                    fclose(fff);

                    retlen = snprintf(name, PAPI_MAX_STR_LEN, "%s:power%i_input", hwmonx->d_name, i);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("Unable to generate name %s:power%i_input\n", hwmonx->d_name, i);
                        closedir(d);
                        closedir(dir);
                        return (PAPI_EINVAL);
                    }

                    snprintf(units, PAPI_MIN_STR_LEN, "microwatts");
                    retlen = snprintf(description, PAPI_MAX_STR_LEN, "%s, %s module, label %s", units, modulename, location);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("snprintf failed.\n");
                        return PAPI_EINVAL;
                    }

                    if (insert_in_list(name, units, description, filename) != PAPI_OK) {
                        goto done_error;
                    }

                    count++;
                }

                for (i = 0; i < 32; i++) {
                    retlen = snprintf(filename, PAPI_MAX_STR_LEN, "%s/fan%d_label", path, i);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("Failed to write fan label string.\n");
                        return PAPI_EINVAL;
                    }
                    fff = fopen(filename, "r");
                    if (fff == NULL) {
                        strncpy(location, "?", PAPI_MIN_STR_LEN);
                    } else {
                        if (fgets(location, PAPI_MIN_STR_LEN, fff) != NULL) {
                            location[strlen(location) - 1] = '\0';
                        }
                        fclose(fff);
                    }

                    retlen = snprintf(filename, PAPI_MAX_STR_LEN, "%s/fan%d_input", path, i);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("Unable to generate filename %s/fan%d_input\n", path, i);
                        closedir(d);
                        closedir(dir);
                        return (PAPI_EINVAL);
                    }

                    fff = fopen(filename, "r");
                    if (fff == NULL) continue;
                    fclose(fff);

                    retlen = snprintf(name, PAPI_MAX_STR_LEN, "%s:fan%i_input", hwmonx->d_name, i);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("Unable to generate name %s:fan%i_input\n", hwmonx->d_name, i);
                        closedir(d);
                        closedir(dir);
                        return (PAPI_EINVAL);
                    }

                    snprintf(units, PAPI_MIN_STR_LEN, "RPM");
                    retlen = snprintf(description, PAPI_MAX_STR_LEN, "%s, %s module, label %s", units, modulename, location);
                    if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                        SUBDBG("snprintf failed.\n");
                        return PAPI_EINVAL;
                    }

                    if (insert_in_list(name, units, description, filename) != PAPI_OK) {
                        goto done_error;
                    }

                    count++;
                }

                closedir(d);
            }
        }
    }

    closedir(dir);

    // Add power and energy measurements from /sys/cray/pm_counters
    const char *base_cray_dir = "/sys/cray/pm_counters/";
    const char *excluded_files[] = {"freshness", "startup", "version"};
    struct dirent *entry;

    DIR *pm_dir = opendir(base_cray_dir);
    if (pm_dir != NULL) {
        while ((entry = readdir(pm_dir)) != NULL) {
            if (entry->d_type == DT_REG) {
                int exclude = 0;
                for (i = 0; i < sizeof(excluded_files) / sizeof(excluded_files[0]); i++) {
                    if (strcmp(entry->d_name, excluded_files[i]) == 0) {
                        exclude = 1;
                        break;
                    }
                }
                if (exclude) continue;

                retlen = snprintf(filename, PATH_MAX, "%s%s", base_cray_dir, entry->d_name);
                if (retlen <= 0 || PATH_MAX <= retlen) {
                    SUBDBG("Failed to construct power file path.\n");
                    return PAPI_EINVAL;
                }

                fff = fopen(filename, "r");
                if (fff == NULL) continue;
                char value[PAPI_MAX_STR_LEN], unit[PAPI_MIN_STR_LEN];
                fscanf(fff, "%s %s", value, unit);
                fclose(fff);

                retlen = snprintf(name, PAPI_MAX_STR_LEN, "craypm:%s", entry->d_name);
                if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                    SUBDBG("Unable to generate name craypm:%s\n", entry->d_name);
                    return (PAPI_EINVAL);
                }

                snprintf(units, PAPI_MIN_STR_LEN, "%s", unit);

                const char *measurement_type = strstr(entry->d_name, "energy") ? "energy measurement" : "power measurement";
                retlen = snprintf(description, PAPI_MAX_STR_LEN, "%s, %s", units, measurement_type);
                if (retlen <= 0 || PAPI_MAX_STR_LEN <= retlen) {
                    SUBDBG("snprintf failed.\n");
                    return PAPI_EINVAL;
                }

                if (insert_in_list(name, units, description, filename) != PAPI_OK) {
                    goto done_error;
                }
                count++;
            }
        }
        closedir(pm_dir);
    }

    return count;

done_error:
    closedir(d);
    closedir(dir);
    return PAPI_ECMP;
}

static long long getEventValue(int index) {
    char buf[PAPI_MAX_STR_LEN];
    long long result;

    if (_coretemp_native_events[index].stone) {
        return _coretemp_native_events[index].value;
    }

    // Reuse the file descriptor to read the event value
    int fd = _coretemp_native_events[index].fd;
    if (fd == -1) {
        return INVALID_RESULT;
    }

#ifdef LSEEK
    // Use lseek to reset the file offset before reading
    if (lseek(fd, 0, SEEK_SET) == -1) {
        return INVALID_RESULT;
    }

    if (read(fd, buf, PAPI_MAX_STR_LEN) <= 0) {
        result = INVALID_RESULT;
    } else {
        char *space_pos = strchr(buf, ' ');
        if (space_pos) {
            *space_pos = '\0';
        }
        result = strtoll(buf, NULL, 10);
    }
#else
    // Use pread at offset 0
    ssize_t bytes_read = pread(fd, buf, PAPI_MAX_STR_LEN - 1, 0);
    if (bytes_read <= 0) {
        return INVALID_RESULT;
    }

    // Null-terminate
    buf[bytes_read] = '\0';

    // If there's a space, cut it off
    char *space_pos = strchr(buf, ' ');
    if (space_pos) {
        *space_pos = '\0';
    }
    result = strtoll(buf, NULL, 10);
#ifdef ENERGYZERO
    if (strstr(_coretemp_native_events[index].name, "energy") != NULL) {
        result -= _coretemp_native_events[index].initial_value;
    }
#endif

#endif

    return result;
}

static int _coretemp_init_thread(hwd_context_t *ctx) {
    (void)ctx;
    return PAPI_OK;
}

static int _coretemp_init_component(int cidx) {
    int retval = PAPI_OK;
    int i = 0;
    struct temp_event *t, *last;

    if (is_initialized)
        goto fn_exit;

    is_initialized = 1;

    num_events = generateEventList("/sys/class/hwmon");

    if (num_events < 0) {
        char *strCpy;
        strCpy = strncpy(_coretemp_vector.cmp_info.disabled_reason, "Cannot open /sys/class/hwmon", PAPI_MAX_STR_LEN);
        _coretemp_vector.cmp_info.disabled_reason[PAPI_MAX_STR_LEN - 1] = 0;
        if (strCpy == NULL) HANDLE_STRING_ERROR;
        retval = PAPI_ECMP;
        goto fn_fail;
    }

    if (num_events == 0) {
        char *strCpy = strncpy(_coretemp_vector.cmp_info.disabled_reason, "No coretemp events found", PAPI_MAX_STR_LEN);
        _coretemp_vector.cmp_info.disabled_reason[PAPI_MAX_STR_LEN - 1] = 0;
        if (strCpy == NULL) HANDLE_STRING_ERROR;
        retval = PAPI_ECMP;
        goto fn_fail;
    }

    t = root;

    _coretemp_native_events = (CORETEMP_native_event_entry_t *)papi_calloc(num_events, sizeof(CORETEMP_native_event_entry_t));
    if (_coretemp_native_events == NULL) {
        int strErr = snprintf(_coretemp_vector.cmp_info.disabled_reason, PAPI_MAX_STR_LEN, "malloc() of _coretemp_native_events failed for %lu bytes.", num_events * sizeof(CORETEMP_native_event_entry_t));
        _coretemp_vector.cmp_info.disabled_reason[PAPI_MAX_STR_LEN - 1] = 0;
        if (strErr > PAPI_MAX_STR_LEN) HANDLE_STRING_ERROR;
        retval = PAPI_ENOMEM;
        goto fn_fail;
    }

    do {
        int retlen;
        retlen = snprintf(_coretemp_native_events[i].name, PAPI_MAX_STR_LEN, "%s", t->name);
        if (retlen <= 0 || retlen >= PAPI_MAX_STR_LEN) HANDLE_STRING_ERROR;

        retlen = snprintf(_coretemp_native_events[i].path, PATH_MAX, "%s", t->path);
        if (retlen <= 0 || retlen >= PATH_MAX) HANDLE_STRING_ERROR;

        retlen = snprintf(_coretemp_native_events[i].units, PAPI_MIN_STR_LEN, "%s", t->units);
        if (retlen <= 0 || retlen >= PAPI_MIN_STR_LEN) HANDLE_STRING_ERROR;

        retlen = snprintf(_coretemp_native_events[i].description, PAPI_MAX_STR_LEN, "%s", t->description);
        if (retlen <= 0 || retlen >= PAPI_MAX_STR_LEN) HANDLE_STRING_ERROR;

        #ifdef READALL
        _coretemp_native_events[i].fd = open(t->path, O_RDONLY); // Open the file and store the file descriptor
        if (_coretemp_native_events[i].fd == -1) {
            PAPIERROR("Error opening file %s", t->path);
            retval = PAPI_ESYS;
            goto fn_fail;
        }
        #else
        _coretemp_native_events[i].fd = -1;
        #endif

        _coretemp_native_events[i].stone = 0;
        _coretemp_native_events[i].resources.selector = i + 1;
        last = t;
        t = t->next;
        papi_free(last);
        i++;
    } while (t != NULL);
    root = NULL;

#ifdef ENERGYZERO
for (i = 0; i < num_events; i++) {
        if (strstr(_coretemp_native_events[i].name, "energy") != NULL) {
            int fd = open(_coretemp_native_events[i].path, O_RDONLY);
            if (fd == -1) {
                PAPIERROR("Error opening file %s for initial energy offset", _coretemp_native_events[i].path);
                retval = PAPI_ESYS;
                goto fn_fail;
            }

            char buf[PAPI_MAX_STR_LEN];
            ssize_t bytes_read = pread(fd, buf, PAPI_MAX_STR_LEN - 1, 0);
            close(fd);

            if (bytes_read <= 0) {
                _coretemp_native_events[i].initial_value = 0;
            } else {
                buf[bytes_read] = '\0';
                char *space_pos = strchr(buf, ' ');
                if (space_pos) *space_pos = '\0';
                _coretemp_native_events[i].initial_value = strtoll(buf, NULL, 10);
            }
        } else {
            _coretemp_native_events[i].initial_value = 0;
        }
    }
#endif

    _coretemp_vector.cmp_info.num_native_events = num_events;
    _coretemp_vector.cmp_info.CmpIdx = cidx;

fn_exit:
    _papi_hwd[cidx]->cmp_info.disabled = retval;
    return retval;
fn_fail:
    goto fn_exit;
}

static int _coretemp_init_control_state(hwd_control_state_t *ctl) {
    int i;
    CORETEMP_control_state_t *coretemp_ctl = (CORETEMP_control_state_t *)ctl;

    for (i = 0; i < num_events; i++) {
        coretemp_ctl->counts[i] = getEventValue(i);
    }

    coretemp_ctl->lastupdate = PAPI_get_real_usec();
    return PAPI_OK;
}

static int _coretemp_start(hwd_context_t *ctx, hwd_control_state_t *ctl) {
    (void)ctx;
    (void)ctl;
    return PAPI_OK;
}

static int _coretemp_read(hwd_context_t *ctx, hwd_control_state_t *ctl, long long **events, int flags) {
    (void)flags;
    (void)ctx;
 //   (void)ctl; 

    CORETEMP_control_state_t *control = (CORETEMP_control_state_t *)ctl;
    long long now = PAPI_get_real_usec();
    int i;

//    if (now - control->lastupdate > REFRESH_LAT) {
#ifdef READALL        
        for (i = 0; i < num_events; i++) {
            control->counts[i] = getEventValue(i);
        }
#else
        for (i = 0; i < control->active_count; i++) {
            int idx = control->active_idx[i];
            control->counts[idx] = getEventValue(idx); 
        }    
#endif
 //       control->lastupdate = now;
 //   }

    *events = control->counts;
    return PAPI_OK;
}

static int _coretemp_stop(hwd_context_t *ctx, hwd_control_state_t *ctl) {
    (void)ctx;
//    (void)ctl;
    CORETEMP_control_state_t *control = (CORETEMP_control_state_t *)ctl;
    int i;
#ifdef READALL
    for (i = 0; i < num_events; i++) {
        control->counts[i] = getEventValue(i);
    }
#else
    for (int i = 0; i < control->active_count; i++) {
        int idx = control->active_idx[i];
        control->counts[idx] = getEventValue(idx);
    }
#endif
    return PAPI_OK;
}

static int _coretemp_shutdown_thread(hwd_context_t *ctx) {
    (void)ctx;
    return PAPI_OK;
}

static int _coretemp_shutdown_component() {
    if (is_initialized) {
        is_initialized = 0;
        for (int i = 0; i < num_events; i++) {
            if (_coretemp_native_events[i].fd != -1) {
                close(_coretemp_native_events[i].fd);
#ifndef READALL                
                 _coretemp_native_events[i].fd = -1;
#endif
            }
        }
        papi_free(_coretemp_native_events);
        _coretemp_native_events = NULL;
    }
    return PAPI_OK;
}

static int _coretemp_ctl(hwd_context_t *ctx, int code, _papi_int_option_t *option) {
    (void)ctx;
    (void)code;
    (void)option;
    return PAPI_OK;
}

static int _coretemp_update_control_state(hwd_control_state_t *ctl, NativeInfo_t *native, int count, hwd_context_t *ctx) {
    int i, index;
    (void)ctx;

#ifndef READALL
    CORETEMP_control_state_t *control = (CORETEMP_control_state_t *)ctl;
    control->active_count = count;
#endif
    for (i = 0; i < count; i++) {
        index = native[i].ni_event;

#ifndef READALL
 // If not opened yet, open now
        if (_coretemp_native_events[index].fd == -1) {
            int fd = open(_coretemp_native_events[index].path, O_RDONLY);
            if (fd == -1) {
                PAPIERROR("Error opening file %s", _coretemp_native_events[index].path);
                return PAPI_ESYS;
            }
            _coretemp_native_events[index].fd = fd;
        }
       control->active_idx[i] = index; 
#endif
        native[i].ni_position = _coretemp_native_events[index].resources.selector - 1;
    }
    return PAPI_OK;
}

static int _coretemp_set_domain(hwd_control_state_t *cntl, int domain) {
    (void)cntl;
    if (PAPI_DOM_ALL != domain)
        return PAPI_EINVAL;

    return PAPI_OK;
}

static int _coretemp_reset(hwd_context_t *ctx, hwd_control_state_t *ctl) {
    (void)ctx;
    (void)ctl;
    return PAPI_OK;
}

static int _coretemp_ntv_enum_events(unsigned int *EventCode, int modifier) {
    int index;

    switch (modifier) {
    case PAPI_ENUM_FIRST:
        if (num_events == 0) {
            return PAPI_ENOEVNT;
        }
        *EventCode = 0;
        return PAPI_OK;

    case PAPI_ENUM_EVENTS:
        index = *EventCode;
        if (index < num_events - 1) {
            *EventCode = *EventCode + 1;
            return PAPI_OK;
        } else {
            return PAPI_ENOEVNT;
        }
        break;

    default:
        return PAPI_EINVAL;
    }
    return PAPI_EINVAL;
}

static int _coretemp_ntv_code_to_name(unsigned int EventCode, char *name, int len) {
    int index = EventCode;

    if (index >= 0 && index < num_events) {
        strncpy(name, _coretemp_native_events[index].name, len);
        return PAPI_OK;
    }
    return PAPI_ENOEVNT;
}

static int _coretemp_ntv_code_to_descr(unsigned int EventCode, char *name, int len) {
    int index = EventCode;

    if (index >= 0 && index < num_events) {
        strncpy(name, _coretemp_native_events[index].description, len);
        return PAPI_OK;
    }
    return PAPI_ENOEVNT;
}

static int _coretemp_ntv_code_to_info(unsigned int EventCode, PAPI_event_info_t *info) {
    int index = EventCode;

    if ((index < 0) || (index >= num_events)) return PAPI_ENOEVNT;

    strncpy(info->symbol, _coretemp_native_events[index].name, sizeof(info->symbol));
    strncpy(info->long_descr, _coretemp_native_events[index].description, sizeof(info->long_descr));
    strncpy(info->units, _coretemp_native_events[index].units, sizeof(info->units));
    info->units[sizeof(info->units) - 1] = '\0';

    return PAPI_OK;
}

papi_vector_t _coretemp_vector = {
    .cmp_info = {
        .name = "coretemp",
        .short_name = "coretemp",
        .description = "Linux hwmon temperature and other info",
        .version = "4.2.1",
        .num_mpx_cntrs = CORETEMP_MAX_COUNTERS,
        .num_cntrs = CORETEMP_MAX_COUNTERS,
        .default_domain = PAPI_DOM_ALL,
        .available_domains = PAPI_DOM_ALL,
        .default_granularity = PAPI_GRN_SYS,
        .available_granularities = PAPI_GRN_SYS,
        .hardware_intr_sig = PAPI_INT_SIGNAL,
        .fast_real_timer = 0,
        .fast_virtual_timer = 0,
        .attach = 0,
        .attach_must_ptrace = 0,
    },
    .size = {
        .context = sizeof(CORETEMP_context_t),
        .control_state = sizeof(CORETEMP_control_state_t),
        .reg_value = sizeof(CORETEMP_register_t),
        .reg_alloc = sizeof(CORETEMP_reg_alloc_t),
    },
    .init_thread = _coretemp_init_thread,
    .init_component = _coretemp_init_component,
    .init_control_state = _coretemp_init_control_state,
    .start = _coretemp_start,
    .stop = _coretemp_stop,
    .read = _coretemp_read,
    .shutdown_thread = _coretemp_shutdown_thread,
    .shutdown_component = _coretemp_shutdown_component,
    .ctl = _coretemp_ctl,
    .update_control_state = _coretemp_update_control_state,
    .set_domain = _coretemp_set_domain,
    .reset = _coretemp_reset,
    .ntv_enum_events = _coretemp_ntv_enum_events,
    .ntv_code_to_name = _coretemp_ntv_code_to_name,
    .ntv_code_to_descr = _coretemp_ntv_code_to_descr,
    .ntv_code_to_info = _coretemp_ntv_code_to_info,
};
